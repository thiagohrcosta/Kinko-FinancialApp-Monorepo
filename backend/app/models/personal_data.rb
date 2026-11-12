# Reads config/personal_data.yml, the inventory of personal data (#82).
#
#   PersonalData.fields                    # every personal column, as Field
#   PersonalData.fields(table: "users")
#   PersonalData.unclassified_columns      # ["users.new_column", ...]
#   PersonalData.to_markdown               # the generated part of docs/privacy/data-inventory.md
module PersonalData
  PATH = Rails.root.join("config/personal_data.yml")
  DOC_PATH = Rails.root.join("../docs/privacy/data-inventory.md")
  DOC_MARKERS = [ "<!-- BEGIN GENERATED: bin/rails privacy:inventory -->", "<!-- END GENERATED -->" ].freeze

  LAWFUL_BASES = %w[contract legal_obligation legitimate_interest consent].freeze
  # Rails and Solid tables: no personal data of ours.
  FRAMEWORK_TABLES = /\A(schema_migrations|ar_internal_metadata|solid_\w+)\z/

  Field = Data.define(:table, :column, :category, :sensitive, :purpose, :basis, :retention, :on_erasure, :notes) do
    def sensitive? = sensitive
  end

  module_function

  def config
    @config ||= YAML.load_file(PATH, aliases: true)
  end

  def reload!
    @config = nil
  end

  def fields(table: nil)
    config.fetch("tables").flat_map do |table_name, columns|
      next [] if table && table_name != table.to_s

      columns.filter_map do |column, entry|
        next if entry == "not_personal"

        Field.new(table: table_name, column: column, category: entry["category"], sensitive: entry["sensitive"] == true,
                  purpose: entry["purpose"], basis: entry["basis"], retention: entry["retention"],
                  on_erasure: entry["on_erasure"], notes: entry["notes"])
      end
    end
  end

  def application_tables(connection = ActiveRecord::Base.connection)
    connection.tables.grep_v(FRAMEWORK_TABLES).sort
  end

  # Columns in the database that personal_data.yml doesn't mention.
  def unclassified_columns(connection = ActiveRecord::Base.connection)
    classified = config.fetch("tables")
    technical = config.fetch("technical_columns")

    application_tables(connection).flat_map do |table|
      connection.columns(table).map(&:name)
                .reject { |column| technical.include?(column) || classified.dig(table, column) }
                .map { |column| "#{table}.#{column}" }
    end
  end

  # Entries in personal_data.yml for columns that no longer exist.
  def stale_entries(connection = ActiveRecord::Base.connection)
    config.fetch("tables").flat_map do |table, columns|
      existing = connection.table_exists?(table) ? connection.columns(table).map(&:name) : []
      (columns.keys - existing).map { |column| "#{table}.#{column}" }
    end
  end

  # Entries whose values aren't in the allowed lists.
  def invalid_entries
    fields.filter_map do |field|
      problems = []
      problems << "category #{field.category.inspect}" unless config["categories"].key?(field.category)
      problems << "basis #{field.basis.inspect}" unless LAWFUL_BASES.include?(field.basis)
      problems << "retention #{field.retention.inspect}" unless config["retention"].key?(field.retention)
      problems << "on_erasure #{field.on_erasure.inspect}" unless config["on_erasure"].key?(field.on_erasure)
      problems << "missing purpose" if field.purpose.blank?
      "#{field.table}.#{field.column}: #{problems.join(', ')}" if problems.any?
    end
  end

  def to_markdown
    MarkdownRenderer.new(config, fields).render
  end

  def write_doc!
    File.write(DOC_PATH, doc_with_generated_section)
  end

  def doc_with_generated_section
    before, rest = File.read(DOC_PATH).split(DOC_MARKERS.first, 2)
    _, after = rest.to_s.split(DOC_MARKERS.last, 2)
    raise "#{DOC_PATH} is missing the generated-section markers" if after.nil?

    "#{before}#{DOC_MARKERS.first}\n#{to_markdown}#{DOC_MARKERS.last}#{after}"
  end

  class MarkdownRenderer
    def initialize(config, fields)
      @config = config
      @fields = fields
    end

    def render
      [ tables, other_stores, recipients, legend ].join("\n")
    end

    private
      def tables
        @fields.group_by(&:table).map do |table, fields|
          rows = fields.map do |f|
            column = f.sensitive? ? "`#{f.column}` ⚠️" : "`#{f.column}`"
            [ column, f.category, f.purpose, f.basis, f.retention, f.on_erasure, f.notes ]
          end
          "### `#{table}`\n\n" + table_markdown(%w[Column Category Purpose Basis Retention On\ erasure Notes], rows)
        end.join("\n")
      end

      def other_stores
        rows = @config.fetch("other_stores").map { |s| s.values_at("name", "where", "retention", "notes") }
        "### Outside the database\n\n" + table_markdown(%w[Store Where Retention Notes], rows)
      end

      def recipients
        rows = @config.fetch("recipients").map { |r| r.values_at("name", "role", "receives", "location", "transfer_mechanism") }
        "### Who else receives personal data\n\n" + table_markdown(%w[Recipient Role Receives Location Transfer\ mechanism], rows)
      end

      def legend
        sections = %w[categories retention on_erasure].map do |key|
          items = @config.fetch(key).map { |name, text| "- `#{name}`: #{text.strip}" }
          "**#{key.humanize}**\n\n#{items.join("\n")}\n"
        end
        "### Legend\n\n⚠️ Sensitive personal information under CPRA.\n\n" + sections.join("\n")
      end

      def table_markdown(headers, rows)
        lines = [ headers, headers.map { "---" } ] + rows.map { |row| row.map { |cell| cell.to_s.strip.tr("\n", " ").gsub("|", "\\|") } }
        lines.map { |cells| "| #{cells.join(' | ')} |" }.join("\n") + "\n"
      end
  end
end
