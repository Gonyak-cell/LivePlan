package com.liveplan.core.util

import java.util.Calendar
import java.util.TimeZone

/**
 * Date key utilities
 * Aligned with iOS AppCore dateKey rules
 *
 * dateKey format: YYYY-MM-DD (user's local timezone)
 */
object DateKeyUtil {

    /**
     * Get today's dateKey in local timezone
     */
    fun today(): String {
        return fromMillis(System.currentTimeMillis())
    }

    /**
     * Convert millis to dateKey
     */
    fun fromMillis(millis: Long, timeZone: TimeZone = TimeZone.getDefault()): String {
        val calendar = Calendar.getInstance(timeZone).apply {
            timeInMillis = millis
        }
        return format(calendar)
    }

    /**
     * Convert dateKey to start of day millis
     */
    fun toStartOfDayMillis(dateKey: String, timeZone: TimeZone = TimeZone.getDefault()): Long {
        val parts = dateKey.split("-")
        require(parts.size == 3) { "Invalid dateKey format: $dateKey" }

        val year = parts[0].toInt()
        val month = parts[1].toInt() - 1 // Calendar months are 0-based
        val day = parts[2].toInt()

        return Calendar.getInstance(timeZone).apply {
            set(year, month, day, 0, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }

    /**
     * Get start of day millis from current time
     */
    fun startOfDay(millis: Long, timeZone: TimeZone = TimeZone.getDefault()): Long {
        return Calendar.getInstance(timeZone).apply {
            timeInMillis = millis
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }

    /**
     * Get end of day millis from current time
     */
    fun endOfDay(millis: Long, timeZone: TimeZone = TimeZone.getDefault()): Long {
        return Calendar.getInstance(timeZone).apply {
            timeInMillis = millis
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 59)
            set(Calendar.SECOND, 59)
            set(Calendar.MILLISECOND, 999)
        }.timeInMillis
    }

    /**
     * Get next day's dateKey
     */
    fun nextDay(dateKey: String): String {
        val millis = toStartOfDayMillis(dateKey)
        val nextDayMillis = millis + 24 * 60 * 60 * 1000L
        return fromMillis(nextDayMillis)
    }

    /**
     * Get previous day's dateKey
     */
    fun previousDay(dateKey: String): String {
        val millis = toStartOfDayMillis(dateKey)
        val prevDayMillis = millis - 24 * 60 * 60 * 1000L
        return fromMillis(prevDayMillis)
    }

    private fun format(calendar: Calendar): String {
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH) + 1
        val day = calendar.get(Calendar.DAY_OF_MONTH)
        return "%04d-%02d-%02d".format(year, month, day)
    }
}
