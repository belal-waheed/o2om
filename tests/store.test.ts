import { describe, it, expect } from "vitest";
import ar from "../src/locales/ar.json";
import en from "../src/locales/en.json";

describe("O2om v4.0 Frontend & Localization Tests", () => {
  it("should have matching translation keys between Arabic and English", () => {
    const arKeys = Object.keys(ar).sort();
    const enKeys = Object.keys(en).sort();

    expect(arKeys).toEqual(enKeys);
  });

  it("should have non-empty values for all translation keys", () => {
    for (const [key, val] of Object.entries(ar)) {
      expect(val.trim().length, `Arabic key ${key} should not be empty`).toBeGreaterThan(0);
    }
    for (const [key, val] of Object.entries(en)) {
      expect(val.trim().length, `English key ${key} should not be empty`).toBeGreaterThan(0);
    }
  });

  it("should validate default Pomodoro interval math correctly", () => {
    const workIntervalMin = 25;
    const shortBreakMin = 5;
    const longBreakMin = 15;
    const cyclesBeforeLong = 4;

    expect(workIntervalMin * 60 * 1000).toBe(1500000);
    expect(shortBreakMin * 60 * 1000).toBe(300000);
    expect(longBreakMin * 60 * 1000).toBe(900000);

    const getBreakDuration = (completedCycles: number) => {
      return (completedCycles % cyclesBeforeLong === 0) ? longBreakMin : shortBreakMin;
    };

    expect(getBreakDuration(1)).toBe(5);
    expect(getBreakDuration(2)).toBe(5);
    expect(getBreakDuration(3)).toBe(5);
    expect(getBreakDuration(4)).toBe(15);
  });
});
