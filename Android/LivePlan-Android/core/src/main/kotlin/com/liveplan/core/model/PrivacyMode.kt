package com.liveplan.core.model

/**
 * Privacy mode for lock screen display
 * Aligned with iOS AppCore PrivacyMode enum
 *
 * Default: LEVEL_1 (masked)
 */
enum class PrivacyMode {
    /**
     * Full title shown (with length limit)
     */
    LEVEL_0,

    /**
     * Project name hidden + task name abbreviated/anonymous + count
     * DEFAULT value
     */
    LEVEL_1,

    /**
     * Count/progress only, no titles
     */
    LEVEL_2;

    companion object {
        val DEFAULT = LEVEL_1
    }
}
