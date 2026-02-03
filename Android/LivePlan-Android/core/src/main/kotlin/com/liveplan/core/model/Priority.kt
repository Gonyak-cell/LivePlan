package com.liveplan.core.model

/**
 * Task priority levels (P1 = highest, P4 = lowest/default)
 * Aligned with iOS AppCore Priority enum
 */
enum class Priority(val value: Int) {
    P1(1),
    P2(2),
    P3(3),
    P4(4);

    companion object {
        val DEFAULT = P4

        fun fromValue(value: Int): Priority =
            entries.find { it.value == value } ?: DEFAULT
    }
}
