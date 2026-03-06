import React, { useState, useMemo } from "react";
import { StyleSheet, View, Text, TouchableOpacity } from "react-native";
import {
  Canvas,
  Path,
  Skia,
  Circle,
  Line,
} from "@shopify/react-native-skia";
import * as d3 from "d3-shape";
import { scaleLinear } from "d3-scale";
import { Gesture, GestureDetector } from "react-native-gesture-handler";

const DATA = {
  "7D": {
    income: [300, 420, 350, 480, 390, 520, 460],
    expenses: [250, 320, 290, 400, 350, 450, 420],
  },
  "14D": {
    income: [200, 350, 280, 420, 300, 500, 380, 600, 450, 650, 480, 700, 550, 750],
    expenses: [150, 250, 200, 350, 260, 420, 310, 500, 370, 520, 390, 560, 420, 600],
  },
  "30D": {
    income: Array.from({ length: 30 }, () => Math.random() * 5000),
    expenses: Array.from({ length: 30 }, () => Math.random() * 4000),
  },
};

export default function InsightChart() {
  const [range, setRange] = useState<"7D" | "14D" | "30D">("7D");
  const [activeIndex, setActiveIndex] = useState<number | null>(null);

  const { income, expenses } = DATA[range];

  const width = 340;
  const height = 200;
  const padding = 35;

  const { yScale, ticks } = useMemo(() => {
    const allValues = [...income, ...expenses];
    const rawMin = Math.min(...allValues);
    const rawMax = Math.max(...allValues);

    const scale = scaleLinear().domain([rawMin, rawMax]).nice(5);
    const [niceMin, niceMax] = scale.domain();
    const generatedTicks = scale.ticks(4);

    const yScale = (value: number) => {
      const scaled =
        ((value - niceMin) / (niceMax - niceMin)) *
        (height - padding * 2);
      return height - padding - scaled;
    };

    return { yScale, ticks: generatedTicks };
  }, [income, expenses]);

  const xScale = (index: number, length: number) =>
    padding + (index * (width - padding * 2)) / (length - 1);

  const createLine = (data: number[]) => {
    const line = d3
      .line<number>()
      .x((_, i) => xScale(i, data.length))
      .y((d) => yScale(d))
      .curve(d3.curveCatmullRom.alpha(0.5));

    return Skia.Path.MakeFromSVGString(line(data) ?? "");
  };

  const createArea = (data: number[]) => {
    const area = d3
      .area<number>()
      .x((_, i) => xScale(i, data.length))
      .y0(height - padding)
      .y1((d) => yScale(d))
      .curve(d3.curveCatmullRom.alpha(0.5));

    return Skia.Path.MakeFromSVGString(area(data) ?? "");
  };

  const incomeLine = createLine(income);
  const expensesLine = createLine(expenses);
  const incomeArea = createArea(income);
  const expensesArea = createArea(expenses);

  const gesture = Gesture.Pan()
    .onUpdate((e) => {
      const relativeX = e.x - padding;
      const step = (width - padding * 2) / (income.length - 1);
      const index = Math.round(relativeX / step);

      if (index >= 0 && index < income.length) {
        setActiveIndex(index);
      }
    })
    .onEnd(() => {
      setActiveIndex(null);
    });

  const formatCurrency = (value: number) => {
    if (value >= 1000000) return `$${(value / 1000000).toFixed(1)}M`;
    if (value >= 1000) return `$${(value / 1000).toFixed(1)}k`;
    return `$${Math.round(value)}`;
  };

  return (
    <View style={styles.card}>
      <View style={styles.header}>
        <Text style={styles.title}>Insight Dashboard</Text>
        <View style={styles.filters}>
          {(["7D", "14D", "30D"] as const).map((r) => (
            <TouchableOpacity
              key={r}
              onPress={() => setRange(r)}
              style={[
                styles.filterBtn,
                range === r && styles.activeFilter,
              ]}
            >
              <Text
                style={[
                  styles.filterText,
                  range === r && styles.activeFilterText,
                ]}
              >
                {r}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      <View style={styles.legend}>
        <Text style={{ color: "#57A773" }}>● Income</Text>
        <Text style={{ color: "#FF3B30" }}>● Expenses</Text>
      </View>

      <GestureDetector gesture={gesture}>
        <View>
          <Canvas style={{ width, height }}>
            {ticks.map((tick, i) => {
              const y = yScale(tick);
              const path = Skia.Path.Make();
              path.moveTo(padding, y);
              path.lineTo(width - padding, y);

              return (
                <Path
                  key={i}
                  path={path}
                  color="rgba(0,0,0,0.06)"
                  style="stroke"
                  strokeWidth={1}
                />
              );
            })}

            <Path path={incomeArea} color="rgba(31, 182, 69, 0.12)" />
            <Path path={expensesArea} color="rgba(242, 1, 1, 0.12)" />

            <Path path={incomeLine} color="#57A773" style="stroke" strokeWidth={3} />
            <Path path={expensesLine} color="#FF3B30" style="stroke" strokeWidth={3} />

            {activeIndex !== null && (
              <>
                <Line
                  p1={{ x: xScale(activeIndex, income.length), y: padding }}
                  p2={{
                    x: xScale(activeIndex, income.length),
                    y: height - padding,
                  }}
                  color="rgba(0,0,0,0.2)"
                  strokeWidth={1}
                />
                <Circle
                  cx={xScale(activeIndex, income.length)}
                  cy={yScale(income[activeIndex])}
                  r={5}
                  color="#57A773"
                />
                <Circle
                  cx={xScale(activeIndex, income.length)}
                  cy={yScale(expenses[activeIndex])}
                  r={5}
                  color="#FF3B30"
                />
              </>
            )}
          </Canvas>

          {/* Y Axis RIGHT */}
          <View style={[styles.yAxis, { height }]}>
            {ticks
              .slice()
              .reverse()
              .map((t, i) => (
                <Text key={i} style={styles.yLabel}>
                  {formatCurrency(t)}
                </Text>
              ))}
          </View>

          {activeIndex !== null && (
            <View
              style={[
                styles.tooltip,
                { left: xScale(activeIndex, income.length) - 60 },
              ]}
            >
              <Text style={styles.tooltipText}>
                Day {activeIndex + 1}
              </Text>
              <Text style={{ color: "##57A773" }}>
                Income: {formatCurrency(income[activeIndex])}
              </Text>
              <Text style={{ color: "##FF3B30" }}>
                Expenses: {formatCurrency(expenses[activeIndex])}
              </Text>
            </View>
          )}
        </View>
      </GestureDetector>

      <View style={styles.daysRow}>
        {income.map((_, i) => (
          <Text key={i} style={styles.dayText}>
            {i + 1}
          </Text>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    marginHorizontal: 20,
    padding: 20,
    borderRadius: 20,
    backgroundColor: "#fff",
    shadowColor: "#000",
    shadowOpacity: 0.05,
    shadowRadius: 10,
    elevation: 3,
  },
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  title: {
    fontSize: 16,
    fontWeight: "600",
  },
  filters: {
    flexDirection: "row",
  },
  filterBtn: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
    backgroundColor: "#eee",
    marginLeft: 8,
  },
  activeFilter: {
    backgroundColor: "#FF3B30",
  },
  filterText: {
    fontSize: 12,
    color: "#333",
  },
  activeFilterText: {
    color: "#fff",
  },
  legend: {
    flexDirection: "row",
    gap: 16,
    marginVertical: 10,
  },
  yAxis: {
    position: "absolute",
    right: 0,
    top: 0,
    justifyContent: "space-between",
    alignItems: "flex-end",
    paddingRight: 5,
  },
  yLabel: {
    fontSize: 10,
    color: "#888",
  },
  daysRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginTop: 8,
    paddingHorizontal: 35,
  },
  dayText: {
    fontSize: 10,
    color: "#888",
  },
  tooltip: {
    position: "absolute",
    top: 10,
    width: 120,
    backgroundColor: "#fff",
    padding: 8,
    borderRadius: 8,
    shadowColor: "#000",
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 3,
  },
  tooltipText: {
    fontWeight: "600",
    marginBottom: 4,
  },
});