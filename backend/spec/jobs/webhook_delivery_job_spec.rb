require "rails_helper"

RSpec.describe WebhookDeliveryJob, type: :job do
  let(:merchant) { create(:user, :business) }
  let!(:endpoint) { WebhookEndpoint.create!(user: merchant, url: "https://merchant.example/hooks") }
  let!(:delivery) { WebhookDelivery.enqueue_for(user: merchant, event_type: "payment_request.paid", data: { id: "pr_1" }) }

  # Captures the outgoing request instead of hitting the network.
  def stub_http(response_class = Net::HTTPOK, code = "200", raise_error: nil)
    sent = {}
    http = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:start) do |host, port, **opts, &block|
      sent.merge!(host: host, port: port, opts: opts)
      block.call(http)
    end
    allow(http).to receive(:request) do |req|
      raise raise_error if raise_error

      sent[:request] = req
      response_class.new("1.1", code, "msg")
    end
    sent
  end

  it "POSTs the signed payload and marks the delivery succeeded" do
    sent = stub_http

    described_class.perform_now(delivery.id)

    req = sent[:request]
    expect(sent).to include(host: "merchant.example", port: 443)
    expect(sent[:opts]).to include(use_ssl: true, open_timeout: 5, read_timeout: 5)
    expect(req["Content-Type"]).to eq("application/json")
    expect(req["Kinko-Event-Id"]).to eq("evt_#{delivery.reload.public_id}")
    expect(Webhooks::Signature.valid?(req.body, req["Kinko-Signature"], endpoint.signing_secret)).to be(true)
    expect(JSON.parse(req.body)).to include("type" => "payment_request.paid", "data" => { "id" => "pr_1" })

    expect(delivery.reload).to have_attributes(status: "succeeded", attempts: 1, last_response_code: 200, last_error: nil)
    expect(delivery.delivered_at).to be_present
  end

  it "does not send a delivery twice once it succeeded" do
    stub_http
    described_class.perform_now(delivery.id)
    described_class.perform_now(delivery.id)

    expect(Net::HTTP).to have_received(:start).once
  end

  it "records a non-2xx response and schedules a retry" do
    stub_http(Net::HTTPInternalServerError, "500")

    expect { described_class.perform_now(delivery.id) }.to have_enqueued_job(described_class).with(delivery.id)
    expect(delivery.reload).to have_attributes(status: "pending", attempts: 1, last_response_code: 500, last_error: "HTTP 500")
  end

  it "records network errors and schedules a retry" do
    stub_http(raise_error: Net::OpenTimeout)

    expect { described_class.perform_now(delivery.id) }.to have_enqueued_job(described_class)
    expect(delivery.reload).to have_attributes(status: "pending", last_error: "Net::OpenTimeout")
  end

  it "marks the delivery failed after the last attempt" do
    stub_http(Net::HTTPInternalServerError, "500")
    job = described_class.new(delivery.id)
    job.exception_executions = { "[WebhookDeliveryJob::DeliveryFailed]" => described_class::MAX_ATTEMPTS - 1 }

    job.perform_now

    expect(delivery.reload.status).to eq("failed")
  end

  it "re-checks the URL at send time (DNS may now point to a private address)" do
    stub_http
    allow(WebhookEndpoint).to receive(:public_target).and_return(nil)

    expect { described_class.perform_now(delivery.id) }.to have_enqueued_job(described_class)
    expect(Net::HTTP).not_to have_received(:start)
    expect(delivery.reload.last_error).to eq("Unsafe URL")
  end

  context "with DNS checks on (production)" do
    before { allow(WebhookEndpoint).to receive(:allow_insecure?).and_return(false) }

    it "connects to the address it checked, so DNS can't change in between (rebinding)" do
      sent = stub_http
      answers = [ [ "93.184.216.34" ], [ "127.0.0.1" ] ]
      allow(Resolv).to receive(:getaddresses).with("merchant.example") { answers.shift }

      described_class.perform_now(delivery.id)

      expect(Resolv).to have_received(:getaddresses).once
      expect(sent).to include(host: "merchant.example")
      expect(sent[:opts]).to include(ipaddr: "93.184.216.34", use_ssl: true)
      expect(delivery.reload.status).to eq("succeeded")
    end

    it "doesn't connect when the host now resolves to a private address" do
      stub_http
      allow(Resolv).to receive(:getaddresses).with("merchant.example").and_return([ "10.0.0.7" ])

      expect { described_class.perform_now(delivery.id) }.to have_enqueued_job(described_class)
      expect(Net::HTTP).not_to have_received(:start)
    end
  end

  it "doesn't follow redirects: a 3xx is a failed attempt" do
    stub_http(Net::HTTPFound, "302")

    expect { described_class.perform_now(delivery.id) }.to have_enqueued_job(described_class)
    expect(delivery.reload).to have_attributes(status: "pending", last_response_code: 302, last_error: "HTTP 302")
  end

  describe "retry schedule" do
    before { freeze_time }

    it "retries after 1 minute first" do
      stub_http(Net::HTTPInternalServerError, "500")

      expect { described_class.perform_now(delivery.id) }
        .to have_enqueued_job(described_class).with(delivery.id).at(1.minute.from_now)
    end

    it "waits longer each time, up to 24 hours" do
      stub_http(Net::HTTPInternalServerError, "500")
      job = described_class.new(delivery.id)
      job.exception_executions = { "[WebhookDeliveryJob::DeliveryFailed]" => 6 } # the 7th attempt is about to fail

      expect { job.perform_now }.to have_enqueued_job(described_class).at(24.hours.from_now)
    end

    it "covers more than a day before giving up" do
      expect(described_class::RETRY_SCHEDULE.sum).to be > 1.day
      expect(described_class::MAX_ATTEMPTS).to eq(8)
    end
  end

  it "fails without sending when the endpoint was disabled" do
    stub_http
    endpoint.update!(active: false)

    described_class.perform_now(delivery.id)

    expect(Net::HTTP).not_to have_received(:start)
    expect(delivery.reload).to have_attributes(status: "failed", last_error: "Endpoint disabled")
  end

  it "ignores deliveries that no longer exist" do
    expect { described_class.perform_now(0) }.not_to raise_error
  end
end
