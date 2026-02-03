package com.liveplan.core.util

import com.liveplan.core.model.RecurrenceKind
import com.liveplan.core.model.RecurrenceRule
import java.util.Calendar
import java.util.TimeZone

/**
 * Calculator for next occurrence based on recurrence rules
 * Aligned with iOS AppCore recurrence calculation
 *
 * Supports:
 * - DAILY: Every N days
 * - WEEKLY: Specific weekdays every N weeks
 * - MONTHLY: Same day every N months
 */
object RecurrenceCalculator {

    /**
     * Calculate the next occurrence time based on recurrence rule
     *
     * @param rule The recurrence rule
     * @param currentOccurrence Current occurrence timestamp (millis)
     * @param timeZone TimeZone for calculation (defaults to device timezone)
     * @return Next occurrence timestamp in millis
     */
    fun calculateNextOccurrence(
        rule: RecurrenceRule,
        currentOccurrence: Long,
        timeZone: TimeZone = TimeZone.getDefault()
    ): Long {
        return when (rule.kind) {
            RecurrenceKind.DAILY -> calculateNextDaily(rule, currentOccurrence, timeZone)
            RecurrenceKind.WEEKLY -> calculateNextWeekly(rule, currentOccurrence, timeZone)
            RecurrenceKind.MONTHLY -> calculateNextMonthly(rule, currentOccurrence, timeZone)
        }
    }

    /**
     * Calculate next daily occurrence
     * Advances by interval days
     */
    private fun calculateNextDaily(
        rule: RecurrenceRule,
        currentOccurrence: Long,
        timeZone: TimeZone
    ): Long {
        val calendar = Calendar.getInstance(timeZone).apply {
            timeInMillis = currentOccurrence
            add(Calendar.DAY_OF_MONTH, rule.interval)
        }
        return applyTimeOfDay(calendar, rule)
    }

    /**
     * Calculate next weekly occurrence
     * Finds the next matching weekday based on rule.weekdays
     *
     * Algorithm:
     * 1. Start from the day after current occurrence
     * 2. Find the next day that matches one of the weekdays
     * 3. If we've checked all 7 days and none match in current week,
     *    advance by (interval - 1) weeks and continue
     */
    private fun calculateNextWeekly(
        rule: RecurrenceRule,
        currentOccurrence: Long,
        timeZone: TimeZone
    ): Long {
        require(rule.weekdays.isNotEmpty()) { "Weekly recurrence must have at least one weekday" }

        val calendar = Calendar.getInstance(timeZone).apply {
            timeInMillis = currentOccurrence
        }

        // ISO-8601: 1=Monday, 7=Sunday
        // Calendar: 1=Sunday, 2=Monday, ... 7=Saturday
        // Convert rule weekdays (ISO) to Calendar format
        val calendarWeekdays = rule.weekdays.map { isoDay ->
            if (isoDay == 7) Calendar.SUNDAY else isoDay + 1
        }.toSet()

        val startDayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
        var daysChecked = 0
        var foundInCurrentWeek = false

        // Move to next day first
        calendar.add(Calendar.DAY_OF_MONTH, 1)
        daysChecked++

        // Check remaining days in current week
        while (daysChecked <= 7) {
            val currentDayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
            if (calendarWeekdays.contains(currentDayOfWeek)) {
                foundInCurrentWeek = true
                break
            }
            calendar.add(Calendar.DAY_OF_MONTH, 1)
            daysChecked++
        }

        if (!foundInCurrentWeek) {
            // No matching day found in current week, shouldn't happen if weekdays is non-empty
            // But as fallback, reset to first weekday of next interval weeks
            calendar.timeInMillis = currentOccurrence
            calendar.add(Calendar.WEEK_OF_YEAR, rule.interval)
            calendar.set(Calendar.DAY_OF_WEEK, calendarWeekdays.first())
        } else if (daysChecked > 7 - getDaysUntilWeekEnd(startDayOfWeek) && rule.interval > 1) {
            // We wrapped to next week, apply interval
            calendar.add(Calendar.WEEK_OF_YEAR, rule.interval - 1)
        }

        return applyTimeOfDay(calendar, rule)
    }

    /**
     * Calculate days until end of week (Sunday) from a given day
     */
    private fun getDaysUntilWeekEnd(dayOfWeek: Int): Int {
        // Calendar.SUNDAY = 1, so days until Sunday from each day:
        // Sunday(1) = 0, Monday(2) = 6, Tuesday(3) = 5, ..., Saturday(7) = 1
        return if (dayOfWeek == Calendar.SUNDAY) 0 else 8 - dayOfWeek
    }

    /**
     * Calculate next monthly occurrence
     * Same day of month, advancing by interval months
     *
     * Handles end-of-month edge cases:
     * - If target month has fewer days, uses last day of month
     * - Example: Jan 31 -> Feb 28/29
     */
    private fun calculateNextMonthly(
        rule: RecurrenceRule,
        currentOccurrence: Long,
        timeZone: TimeZone
    ): Long {
        val calendar = Calendar.getInstance(timeZone).apply {
            timeInMillis = currentOccurrence
        }

        val targetDayOfMonth = calendar.get(Calendar.DAY_OF_MONTH)

        // Add interval months
        calendar.add(Calendar.MONTH, rule.interval)

        // Handle day overflow (e.g., Jan 31 -> Feb doesn't have 31st)
        val maxDayInMonth = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        if (targetDayOfMonth > maxDayInMonth) {
            calendar.set(Calendar.DAY_OF_MONTH, maxDayInMonth)
        } else {
            calendar.set(Calendar.DAY_OF_MONTH, targetDayOfMonth)
        }

        return applyTimeOfDay(calendar, rule)
    }

    /**
     * Apply time of day from rule if specified, otherwise preserve original time
     */
    private fun applyTimeOfDay(calendar: Calendar, rule: RecurrenceRule): Long {
        rule.timeOfDayMinutes?.let { minutes ->
            calendar.set(Calendar.HOUR_OF_DAY, minutes / 60)
            calendar.set(Calendar.MINUTE, minutes % 60)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
        }
        return calendar.timeInMillis
    }
}
