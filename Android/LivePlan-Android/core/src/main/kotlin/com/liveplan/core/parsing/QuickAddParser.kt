package com.liveplan.core.parsing

import com.liveplan.core.model.Priority
import com.liveplan.core.util.DateKeyUtil
import java.util.Calendar
import java.util.TimeZone
import javax.inject.Inject

/**
 * Quick add task parser
 * Aligned with iOS AppCore QuickAddParser
 *
 * Parses text input for quick task creation with limited token support:
 * - 날짜: 내일, 모레, 오늘, 요일(월~일), 오후/오전 N시, Npm/Nam
 * - 우선순위: p1, p2, p3, p4
 * - 태그: #tag
 * - 프로젝트: @project
 * - 섹션: /section or ::section
 *
 * Parsing failure: falls back to using original text as title (no crash)
 */
class QuickAddParser @Inject constructor() {

    /**
     * Parse result containing extracted tokens
     */
    data class ParseResult(
        /** Cleaned title (tokens removed) */
        val title: String,
        /** Extracted due date (millis, null if not found) */
        val dueAt: Long? = null,
        /** Extracted priority (null if not found) */
        val priority: Priority? = null,
        /** Extracted tag names */
        val tags: List<String> = emptyList(),
        /** Extracted project name (null if not found) */
        val projectName: String? = null,
        /** Extracted section name (null if not found) */
        val sectionName: String? = null,
        /** Whether any tokens were found */
        val hasTokens: Boolean = false
    )

    companion object {
        // Date patterns (Korean)
        private val DATE_PATTERNS = mapOf(
            "오늘" to 0,
            "내일" to 1,
            "모레" to 2
        )

        // Weekday patterns (Korean)
        private val WEEKDAY_PATTERNS = mapOf(
            "월" to Calendar.MONDAY,
            "월요일" to Calendar.MONDAY,
            "화" to Calendar.TUESDAY,
            "화요일" to Calendar.TUESDAY,
            "수" to Calendar.WEDNESDAY,
            "수요일" to Calendar.WEDNESDAY,
            "목" to Calendar.THURSDAY,
            "목요일" to Calendar.THURSDAY,
            "금" to Calendar.FRIDAY,
            "금요일" to Calendar.FRIDAY,
            "토" to Calendar.SATURDAY,
            "토요일" to Calendar.SATURDAY,
            "일" to Calendar.SUNDAY,
            "일요일" to Calendar.SUNDAY
        )

        // Priority pattern: p1, p2, p3, p4 (case insensitive)
        private val PRIORITY_REGEX = Regex("""(?i)\bp([1-4])\b""")

        // Tag pattern: #tag (alphanumeric + Korean + underscore)
        private val TAG_REGEX = Regex("""#([\w가-힣_]+)""")

        // Project pattern: @project
        private val PROJECT_REGEX = Regex("""@([\w가-힣_]+)""")

        // Section pattern: /section or ::section
        private val SECTION_REGEX = Regex("""(?:/|::)([\w가-힣_]+)""")

        // Time patterns (Korean): 오전/오후 N시
        private val TIME_KR_REGEX = Regex("""(오전|오후)\s*(\d{1,2})시""")

        // Time patterns (English): Npm, Nam
        private val TIME_EN_REGEX = Regex("""(?i)(\d{1,2})\s*(am|pm)""")
    }

    /**
     * Parse input text and extract tokens
     *
     * @param input Raw input text
     * @param baseTimeMillis Base time for date calculations (default: now)
     * @return ParseResult with extracted tokens
     */
    fun parse(
        input: String,
        baseTimeMillis: Long = System.currentTimeMillis()
    ): ParseResult {
        if (input.isBlank()) {
            return ParseResult(title = "")
        }

        var remaining = input.trim()
        var hasTokens = false

        // Extract priority
        val priority = extractPriority(remaining)
        if (priority != null) {
            remaining = PRIORITY_REGEX.replace(remaining, "")
            hasTokens = true
        }

        // Extract tags
        val tags = extractTags(remaining)
        if (tags.isNotEmpty()) {
            remaining = TAG_REGEX.replace(remaining, "")
            hasTokens = true
        }

        // Extract project
        val projectName = extractProject(remaining)
        if (projectName != null) {
            remaining = PROJECT_REGEX.replace(remaining, "")
            hasTokens = true
        }

        // Extract section
        val sectionName = extractSection(remaining)
        if (sectionName != null) {
            remaining = SECTION_REGEX.replace(remaining, "")
            hasTokens = true
        }

        // Extract date/time
        val (dueAt, remainingAfterDate) = extractDateTime(remaining, baseTimeMillis)
        if (dueAt != null) {
            remaining = remainingAfterDate
            hasTokens = true
        }

        // Clean up title
        val title = cleanTitle(remaining)

        // Fallback: if title is empty after parsing, use original
        val finalTitle = if (title.isBlank()) input.trim() else title

        return ParseResult(
            title = finalTitle,
            dueAt = dueAt,
            priority = priority,
            tags = tags,
            projectName = projectName,
            sectionName = sectionName,
            hasTokens = hasTokens
        )
    }

    private fun extractPriority(text: String): Priority? {
        val match = PRIORITY_REGEX.find(text) ?: return null
        val value = match.groupValues[1].toIntOrNull() ?: return null
        return Priority.fromValue(value)
    }

    private fun extractTags(text: String): List<String> {
        return TAG_REGEX.findAll(text)
            .map { it.groupValues[1] }
            .toList()
    }

    private fun extractProject(text: String): String? {
        return PROJECT_REGEX.find(text)?.groupValues?.get(1)
    }

    private fun extractSection(text: String): String? {
        return SECTION_REGEX.find(text)?.groupValues?.get(1)
    }

    private fun extractDateTime(
        text: String,
        baseTimeMillis: Long
    ): Pair<Long?, String> {
        var remaining = text
        var baseDate: Calendar? = null

        // Extract date (오늘/내일/모레)
        for ((pattern, daysOffset) in DATE_PATTERNS) {
            if (text.contains(pattern)) {
                baseDate = createCalendar(baseTimeMillis).apply {
                    add(Calendar.DAY_OF_MONTH, daysOffset)
                }
                remaining = remaining.replace(pattern, "")
                break
            }
        }

        // Extract weekday if no date found
        // Match only standalone weekday patterns (not part of other words)
        if (baseDate == null) {
            for ((pattern, dayOfWeek) in WEEKDAY_PATTERNS) {
                // Use lookbehind/lookahead for word boundary (space or start/end)
                val wordPattern = Regex("""(?<=\s|^)${Regex.escape(pattern)}(?=\s|$)""")
                if (wordPattern.containsMatchIn(text)) {
                    baseDate = getNextWeekday(baseTimeMillis, dayOfWeek)
                    remaining = wordPattern.replace(remaining, "")
                    break
                }
            }
        }

        // If no date found, check if time-only is specified
        if (baseDate == null && (TIME_KR_REGEX.containsMatchIn(text) || TIME_EN_REGEX.containsMatchIn(text))) {
            // Time without date means today
            baseDate = createCalendar(baseTimeMillis)
        }

        // Extract time (Korean)
        val timeKrMatch = TIME_KR_REGEX.find(remaining)
        if (timeKrMatch != null && baseDate != null) {
            val ampm = timeKrMatch.groupValues[1]
            val hour = timeKrMatch.groupValues[2].toIntOrNull() ?: 12
            val hour24 = when {
                ampm == "오전" && hour == 12 -> 0
                ampm == "오전" -> hour
                ampm == "오후" && hour == 12 -> 12
                else -> hour + 12
            }
            baseDate.apply {
                set(Calendar.HOUR_OF_DAY, hour24)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            remaining = TIME_KR_REGEX.replace(remaining, "")
        }

        // Extract time (English)
        val timeEnMatch = TIME_EN_REGEX.find(remaining)
        if (timeEnMatch != null && baseDate != null) {
            val hour = timeEnMatch.groupValues[1].toIntOrNull() ?: 12
            val ampm = timeEnMatch.groupValues[2].lowercase()
            val hour24 = when {
                ampm == "am" && hour == 12 -> 0
                ampm == "am" -> hour
                ampm == "pm" && hour == 12 -> 12
                else -> hour + 12
            }
            baseDate.apply {
                set(Calendar.HOUR_OF_DAY, hour24)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            remaining = TIME_EN_REGEX.replace(remaining, "")
        }

        // If date found but no time, set to end of day (23:59)
        if (baseDate != null && timeKrMatch == null && timeEnMatch == null) {
            baseDate.apply {
                set(Calendar.HOUR_OF_DAY, 23)
                set(Calendar.MINUTE, 59)
                set(Calendar.SECOND, 59)
                set(Calendar.MILLISECOND, 999)
            }
        }

        return Pair(baseDate?.timeInMillis, remaining)
    }

    private fun createCalendar(timeMillis: Long): Calendar {
        return Calendar.getInstance(TimeZone.getDefault()).apply {
            this.timeInMillis = timeMillis
        }
    }

    private fun getNextWeekday(baseTimeMillis: Long, targetDayOfWeek: Int): Calendar {
        val calendar = createCalendar(baseTimeMillis)
        val currentDayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)

        var daysToAdd = targetDayOfWeek - currentDayOfWeek
        if (daysToAdd <= 0) {
            daysToAdd += 7 // Next week
        }

        calendar.add(Calendar.DAY_OF_MONTH, daysToAdd)
        return calendar
    }

    private fun cleanTitle(text: String): String {
        return text
            .replace(Regex("""\s+"""), " ")  // Multiple spaces to single
            .trim()
    }
}
