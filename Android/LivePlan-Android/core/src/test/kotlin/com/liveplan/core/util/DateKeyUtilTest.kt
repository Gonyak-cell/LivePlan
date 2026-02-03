package com.liveplan.core.util

import org.junit.Assert.*
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

/**
 * Tests for DateKeyUtil
 * Covers: dateKey format, midnight boundary, timezone handling
 */
class DateKeyUtilTest {

    // ─────────────────────────────────────
    // Basic Format Tests
    // ─────────────────────────────────────

    @Test
    fun `fromMillis returns YYYY-MM-DD format`() {
        val calendar = Calendar.getInstance(TimeZone.getDefault()).apply {
            set(2026, Calendar.FEBRUARY, 3, 10, 30, 0)
        }

        val dateKey = DateKeyUtil.fromMillis(calendar.timeInMillis)

        assertEquals("2026-02-03", dateKey)
    }

    @Test
    fun `fromMillis pads single digit month and day`() {
        val calendar = Calendar.getInstance(TimeZone.getDefault()).apply {
            set(2026, Calendar.JANUARY, 5, 10, 30, 0)
        }

        val dateKey = DateKeyUtil.fromMillis(calendar.timeInMillis)

        assertEquals("2026-01-05", dateKey)
    }

    @Test
    fun `today returns current date in YYYY-MM-DD format`() {
        val today = DateKeyUtil.today()

        // Should match pattern YYYY-MM-DD
        assertTrue(today.matches(Regex("""\d{4}-\d{2}-\d{2}""")))
    }

    // ─────────────────────────────────────
    // B4: Midnight Boundary (23:59 / 00:01)
    // ─────────────────────────────────────

    @Test
    fun `23_59 same day as 00_00`() {
        val calendar2359 = Calendar.getInstance(TimeZone.getDefault()).apply {
            set(2026, Calendar.FEBRUARY, 3, 23, 59, 59)
            set(Calendar.MILLISECOND, 999)
        }
        val calendar0000 = Calendar.getInstance(TimeZone.getDefault()).apply {
            set(2026, Calendar.FEBRUARY, 3, 0, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val dateKey2359 = DateKeyUtil.fromMillis(calendar2359.timeInMillis)
        val dateKey0000 = DateKeyUtil.fromMillis(calendar0000.timeInMillis)

        assertEquals("2026-02-03", dateKey2359)
        assertEquals("2026-02-03", dateKey0000)
        assertEquals(dateKey2359, dateKey0000)
    }

    @Test
    fun `00_01 next day is different from 23_59 previous day`() {
        val calendar2359 = Calendar.getInstance(TimeZone.getDefault()).apply {
            set(2026, Calendar.FEBRUARY, 3, 23, 59, 59)
        }
        val calendar0001 = Calendar.getInstance(TimeZone.getDefault()).apply {
            set(2026, Calendar.FEBRUARY, 4, 0, 1, 0)
        }

        val dateKey2359 = DateKeyUtil.fromMillis(calendar2359.timeInMillis)
        val dateKey0001 = DateKeyUtil.fromMillis(calendar0001.timeInMillis)

        assertEquals("2026-02-03", dateKey2359)
        assertEquals("2026-02-04", dateKey0001)
        assertNotEquals(dateKey2359, dateKey0001)
    }

    @Test
    fun `midnight transition changes dateKey`() {
        val beforeMidnight = Calendar.getInstance(TimeZone.getDefault()).apply {
            set(2026, Calendar.FEBRUARY, 3, 23, 59, 59)
            set(Calendar.MILLISECOND, 999)
        }
        val afterMidnight = Calendar.getInstance(TimeZone.getDefault()).apply {
            set(2026, Calendar.FEBRUARY, 4, 0, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val dateBefore = DateKeyUtil.fromMillis(beforeMidnight.timeInMillis)
        val dateAfter = DateKeyUtil.fromMillis(afterMidnight.timeInMillis)

        assertEquals("2026-02-03", dateBefore)
        assertEquals("2026-02-04", dateAfter)
    }

    // ─────────────────────────────────────
    // B5: Timezone Handling
    // ─────────────────────────────────────

    @Test
    fun `same millis different timezone gives different dateKey`() {
        // Use a fixed time that falls on different days in different timezones
        // UTC: 2026-02-03 23:00 -> KST: 2026-02-04 08:00
        val utcCalendar = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            set(2026, Calendar.FEBRUARY, 3, 23, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val millis = utcCalendar.timeInMillis

        val utcDateKey = DateKeyUtil.fromMillis(millis, TimeZone.getTimeZone("UTC"))
        val kstDateKey = DateKeyUtil.fromMillis(millis, TimeZone.getTimeZone("Asia/Seoul"))

        assertEquals("2026-02-03", utcDateKey)
        assertEquals("2026-02-04", kstDateKey)
    }

    @Test
    fun `timezone change does not crash`() {
        val millis = System.currentTimeMillis()

        // Various timezones should not crash
        val timezones = listOf(
            TimeZone.getTimeZone("UTC"),
            TimeZone.getTimeZone("Asia/Seoul"),
            TimeZone.getTimeZone("America/New_York"),
            TimeZone.getTimeZone("Europe/London"),
            TimeZone.getTimeZone("Pacific/Auckland")
        )

        timezones.forEach { tz ->
            val dateKey = DateKeyUtil.fromMillis(millis, tz)
            assertTrue(dateKey.matches(Regex("""\d{4}-\d{2}-\d{2}""")))
        }
    }

    // ─────────────────────────────────────
    // toStartOfDayMillis
    // ─────────────────────────────────────

    @Test
    fun `toStartOfDayMillis returns midnight`() {
        val dateKey = "2026-02-03"
        val millis = DateKeyUtil.toStartOfDayMillis(dateKey)

        val calendar = Calendar.getInstance(TimeZone.getDefault()).apply {
            timeInMillis = millis
        }

        assertEquals(2026, calendar.get(Calendar.YEAR))
        assertEquals(Calendar.FEBRUARY, calendar.get(Calendar.MONTH))
        assertEquals(3, calendar.get(Calendar.DAY_OF_MONTH))
        assertEquals(0, calendar.get(Calendar.HOUR_OF_DAY))
        assertEquals(0, calendar.get(Calendar.MINUTE))
        assertEquals(0, calendar.get(Calendar.SECOND))
        assertEquals(0, calendar.get(Calendar.MILLISECOND))
    }

    @Test
    fun `toStartOfDayMillis with invalid format throws`() {
        assertThrows(IllegalArgumentException::class.java) {
            DateKeyUtil.toStartOfDayMillis("invalid")
        }
    }

    @Test
    fun `toStartOfDayMillis with empty string throws`() {
        assertThrows(IllegalArgumentException::class.java) {
            DateKeyUtil.toStartOfDayMillis("")
        }
    }

    // ─────────────────────────────────────
    // nextDay / previousDay
    // ─────────────────────────────────────

    @Test
    fun `nextDay increments by one day`() {
        assertEquals("2026-02-04", DateKeyUtil.nextDay("2026-02-03"))
        assertEquals("2026-03-01", DateKeyUtil.nextDay("2026-02-28"))
        assertEquals("2027-01-01", DateKeyUtil.nextDay("2026-12-31"))
    }

    @Test
    fun `previousDay decrements by one day`() {
        assertEquals("2026-02-02", DateKeyUtil.previousDay("2026-02-03"))
        assertEquals("2026-02-28", DateKeyUtil.previousDay("2026-03-01"))
        assertEquals("2025-12-31", DateKeyUtil.previousDay("2026-01-01"))
    }

    @Test
    fun `leap year February 29 handled correctly`() {
        // 2024 is a leap year
        assertEquals("2024-02-29", DateKeyUtil.nextDay("2024-02-28"))
        assertEquals("2024-03-01", DateKeyUtil.nextDay("2024-02-29"))
    }

    // ─────────────────────────────────────
    // Round-trip Tests
    // ─────────────────────────────────────

    @Test
    fun `fromMillis and toStartOfDayMillis round-trip`() {
        val originalDateKey = "2026-02-03"
        val millis = DateKeyUtil.toStartOfDayMillis(originalDateKey)
        val roundTripDateKey = DateKeyUtil.fromMillis(millis)

        assertEquals(originalDateKey, roundTripDateKey)
    }

    @Test
    fun `fromMillis ignores time component`() {
        val morning = Calendar.getInstance(TimeZone.getDefault()).apply {
            set(2026, Calendar.FEBRUARY, 3, 6, 30, 0)
        }
        val evening = Calendar.getInstance(TimeZone.getDefault()).apply {
            set(2026, Calendar.FEBRUARY, 3, 18, 30, 0)
        }

        val morningKey = DateKeyUtil.fromMillis(morning.timeInMillis)
        val eveningKey = DateKeyUtil.fromMillis(evening.timeInMillis)

        assertEquals(morningKey, eveningKey)
    }
}
