package com.liveplan.core.util

import com.liveplan.core.model.RecurrenceKind
import com.liveplan.core.model.RecurrenceRule
import org.junit.Assert.*
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

/**
 * Tests for RecurrenceCalculator
 *
 * Verifies correct calculation of next occurrence for:
 * - DAILY recurrence (with interval)
 * - WEEKLY recurrence (with weekdays and interval)
 * - MONTHLY recurrence (with interval and edge cases)
 */
class RecurrenceCalculatorTest {

    private val timeZone = TimeZone.getTimeZone("Asia/Seoul")

    // ─────────────────────────────────────
    // DAILY Recurrence Tests
    // ─────────────────────────────────────

    @Test
    fun `daily recurrence with interval 1 advances by 1 day`() {
        val rule = createDailyRule(interval = 1)
        val current = createDateTime(2026, 2, 3, 10, 0) // Feb 3, 2026

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        assertDateTime(2026, 2, 4, 10, 0, next) // Feb 4, 2026
    }

    @Test
    fun `daily recurrence with interval 3 advances by 3 days`() {
        val rule = createDailyRule(interval = 3)
        val current = createDateTime(2026, 2, 3, 14, 30) // Feb 3, 2026 14:30

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        assertDateTime(2026, 2, 6, 14, 30, next) // Feb 6, 2026 14:30
    }

    @Test
    fun `daily recurrence crosses month boundary`() {
        val rule = createDailyRule(interval = 1)
        val current = createDateTime(2026, 1, 31, 9, 0) // Jan 31, 2026

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        assertDateTime(2026, 2, 1, 9, 0, next) // Feb 1, 2026
    }

    @Test
    fun `daily recurrence crosses year boundary`() {
        val rule = createDailyRule(interval = 1)
        val current = createDateTime(2025, 12, 31, 23, 0) // Dec 31, 2025

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        assertDateTime(2026, 1, 1, 23, 0, next) // Jan 1, 2026
    }

    @Test
    fun `daily recurrence with timeOfDay applies specified time`() {
        val rule = createDailyRule(interval = 1, timeOfDayMinutes = 9 * 60) // 09:00
        val current = createDateTime(2026, 2, 3, 14, 30) // Feb 3, 2026 14:30

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        assertDateTime(2026, 2, 4, 9, 0, next) // Feb 4, 2026 09:00
    }

    // ─────────────────────────────────────
    // WEEKLY Recurrence Tests
    // ─────────────────────────────────────

    @Test
    fun `weekly recurrence finds next weekday in same week`() {
        // Monday = 1, Wednesday = 3, Friday = 5 (ISO-8601)
        val rule = createWeeklyRule(weekdays = setOf(1, 3, 5), interval = 1)
        // Feb 3, 2026 is Tuesday (ISO: 2)
        val current = createDateTime(2026, 2, 2, 10, 0) // Monday Feb 2

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        // Next should be Wednesday Feb 4 (ISO: 3)
        assertDateTime(2026, 2, 4, 10, 0, next)
    }

    @Test
    fun `weekly recurrence wraps to next week when no more days`() {
        // Monday = 1 (ISO-8601)
        val rule = createWeeklyRule(weekdays = setOf(1), interval = 1)
        // Feb 2, 2026 is Monday, so next Monday should be Feb 9
        val current = createDateTime(2026, 2, 2, 10, 0) // Monday

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        assertDateTime(2026, 2, 9, 10, 0, next) // Next Monday
    }

    @Test
    fun `weekly recurrence with interval 2 skips a week`() {
        // Monday = 1 (ISO-8601)
        val rule = createWeeklyRule(weekdays = setOf(1), interval = 2)
        val current = createDateTime(2026, 2, 2, 10, 0) // Monday Feb 2

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        // With interval 2, next should be 2 weeks later: Feb 16
        assertDateTime(2026, 2, 16, 10, 0, next)
    }

    @Test
    fun `weekly recurrence sunday handling`() {
        // Sunday = 7 (ISO-8601)
        val rule = createWeeklyRule(weekdays = setOf(7), interval = 1)
        // Feb 6, 2026 is Friday
        val current = createDateTime(2026, 2, 6, 10, 0) // Friday

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        // Next Sunday is Feb 8
        assertDateTime(2026, 2, 8, 10, 0, next)
    }

    @Test
    fun `weekly recurrence with multiple weekdays finds nearest`() {
        // Tuesday = 2, Thursday = 4, Saturday = 6 (ISO-8601)
        val rule = createWeeklyRule(weekdays = setOf(2, 4, 6), interval = 1)
        // Feb 3, 2026 is Tuesday
        val current = createDateTime(2026, 2, 3, 10, 0) // Tuesday

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        // Next should be Thursday Feb 5
        assertDateTime(2026, 2, 5, 10, 0, next)
    }

    // ─────────────────────────────────────
    // MONTHLY Recurrence Tests
    // ─────────────────────────────────────

    @Test
    fun `monthly recurrence with interval 1 advances by 1 month`() {
        val rule = createMonthlyRule(interval = 1)
        val current = createDateTime(2026, 2, 15, 10, 0) // Feb 15

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        assertDateTime(2026, 3, 15, 10, 0, next) // Mar 15
    }

    @Test
    fun `monthly recurrence with interval 3 advances by 3 months`() {
        val rule = createMonthlyRule(interval = 3)
        val current = createDateTime(2026, 1, 10, 14, 0) // Jan 10

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        assertDateTime(2026, 4, 10, 14, 0, next) // Apr 10
    }

    @Test
    fun `monthly recurrence handles end of month - Jan 31 to Feb`() {
        val rule = createMonthlyRule(interval = 1)
        val current = createDateTime(2026, 1, 31, 10, 0) // Jan 31

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        // Feb 2026 has 28 days, so should be Feb 28
        assertDateTime(2026, 2, 28, 10, 0, next)
    }

    @Test
    fun `monthly recurrence handles leap year Feb 29`() {
        val rule = createMonthlyRule(interval = 1)
        // 2024 is a leap year
        val current = createDateTime(2024, 1, 29, 10, 0) // Jan 29, 2024

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        // Feb 2024 has 29 days (leap year)
        assertDateTime(2024, 2, 29, 10, 0, next)
    }

    @Test
    fun `monthly recurrence handles Jan 30 to Feb (non-leap year)`() {
        val rule = createMonthlyRule(interval = 1)
        val current = createDateTime(2026, 1, 30, 10, 0) // Jan 30, 2026

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        // Feb 2026 has 28 days
        assertDateTime(2026, 2, 28, 10, 0, next)
    }

    @Test
    fun `monthly recurrence crosses year boundary`() {
        val rule = createMonthlyRule(interval = 1)
        val current = createDateTime(2025, 12, 15, 10, 0) // Dec 15, 2025

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        assertDateTime(2026, 1, 15, 10, 0, next) // Jan 15, 2026
    }

    @Test
    fun `monthly recurrence with timeOfDay applies specified time`() {
        val rule = createMonthlyRule(interval = 1, timeOfDayMinutes = 18 * 60 + 30) // 18:30
        val current = createDateTime(2026, 2, 15, 10, 0) // Feb 15, 10:00

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, timeZone)

        assertDateTime(2026, 3, 15, 18, 30, next) // Mar 15, 18:30
    }

    // ─────────────────────────────────────
    // Edge Cases
    // ─────────────────────────────────────

    @Test
    fun `handles DST transition gracefully`() {
        // This test uses a timezone with DST to ensure calculations work across transitions
        val dstTimeZone = TimeZone.getTimeZone("America/New_York")
        val rule = createDailyRule(interval = 1)
        // March 8, 2026 is around DST transition in US
        val current = createDateTime(2026, 3, 8, 2, 0, dstTimeZone)

        val next = RecurrenceCalculator.calculateNextOccurrence(rule, current, dstTimeZone)

        // Should advance to March 9 without crashing
        val calendar = Calendar.getInstance(dstTimeZone).apply { timeInMillis = next }
        assertEquals(2026, calendar.get(Calendar.YEAR))
        assertEquals(Calendar.MARCH, calendar.get(Calendar.MONTH))
        assertEquals(9, calendar.get(Calendar.DAY_OF_MONTH))
    }

    // ─────────────────────────────────────
    // Helper Functions
    // ─────────────────────────────────────

    private fun createDailyRule(
        interval: Int = 1,
        timeOfDayMinutes: Int? = null
    ): RecurrenceRule {
        return RecurrenceRule(
            kind = RecurrenceKind.DAILY,
            interval = interval,
            timeOfDayMinutes = timeOfDayMinutes,
            anchorDateMillis = System.currentTimeMillis()
        )
    }

    private fun createWeeklyRule(
        weekdays: Set<Int>,
        interval: Int = 1,
        timeOfDayMinutes: Int? = null
    ): RecurrenceRule {
        return RecurrenceRule(
            kind = RecurrenceKind.WEEKLY,
            interval = interval,
            weekdays = weekdays,
            timeOfDayMinutes = timeOfDayMinutes,
            anchorDateMillis = System.currentTimeMillis()
        )
    }

    private fun createMonthlyRule(
        interval: Int = 1,
        timeOfDayMinutes: Int? = null
    ): RecurrenceRule {
        return RecurrenceRule(
            kind = RecurrenceKind.MONTHLY,
            interval = interval,
            timeOfDayMinutes = timeOfDayMinutes,
            anchorDateMillis = System.currentTimeMillis()
        )
    }

    private fun createDateTime(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        tz: TimeZone = timeZone
    ): Long {
        return Calendar.getInstance(tz).apply {
            set(year, month - 1, day, hour, minute, 0) // Calendar months are 0-based
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }

    private fun assertDateTime(
        expectedYear: Int,
        expectedMonth: Int,
        expectedDay: Int,
        expectedHour: Int,
        expectedMinute: Int,
        actualMillis: Long
    ) {
        val calendar = Calendar.getInstance(timeZone).apply {
            timeInMillis = actualMillis
        }

        assertEquals("Year mismatch", expectedYear, calendar.get(Calendar.YEAR))
        assertEquals("Month mismatch", expectedMonth, calendar.get(Calendar.MONTH) + 1)
        assertEquals("Day mismatch", expectedDay, calendar.get(Calendar.DAY_OF_MONTH))
        assertEquals("Hour mismatch", expectedHour, calendar.get(Calendar.HOUR_OF_DAY))
        assertEquals("Minute mismatch", expectedMinute, calendar.get(Calendar.MINUTE))
    }
}
