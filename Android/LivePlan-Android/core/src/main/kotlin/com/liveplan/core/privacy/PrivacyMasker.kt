package com.liveplan.core.privacy

import com.liveplan.core.model.PrivacyMode
import javax.inject.Inject

/**
 * Masks task/project titles based on privacy mode
 * Aligned with iOS AppCore PrivacyMasker
 */
class PrivacyMasker @Inject constructor() {

    companion object {
        private const val MAX_TITLE_LENGTH = 24
        private const val ELLIPSIS = "…"
    }

    /**
     * Mask task title based on privacy mode
     *
     * @param title Original title
     * @param privacyMode Privacy mode
     * @param index Optional index for anonymous naming (1-based)
     * @return Masked title
     */
    fun maskTitle(
        title: String,
        privacyMode: PrivacyMode,
        index: Int? = null
    ): String {
        return when (privacyMode) {
            PrivacyMode.LEVEL_0 -> {
                // Full title with length limit
                truncate(title, MAX_TITLE_LENGTH)
            }
            PrivacyMode.LEVEL_1 -> {
                // Anonymous: "할 일 1", "할 일 2", etc.
                if (index != null) {
                    "할 일 $index"
                } else {
                    // Truncate to first few chars + mask
                    abbreviate(title)
                }
            }
            PrivacyMode.LEVEL_2 -> {
                // No title at all
                ""
            }
        }
    }

    /**
     * Mask project name based on privacy mode
     */
    fun maskProjectName(
        name: String,
        privacyMode: PrivacyMode
    ): String {
        return when (privacyMode) {
            PrivacyMode.LEVEL_0 -> truncate(name, MAX_TITLE_LENGTH)
            PrivacyMode.LEVEL_1 -> "프로젝트"
            PrivacyMode.LEVEL_2 -> ""
        }
    }

    private fun truncate(text: String, maxLength: Int): String {
        return if (text.length <= maxLength) {
            text
        } else {
            text.take(maxLength - 1) + ELLIPSIS
        }
    }

    private fun abbreviate(text: String): String {
        // Take first 2-3 characters + mask
        val visibleChars = minOf(3, text.length)
        return if (text.length <= visibleChars) {
            text
        } else {
            text.take(visibleChars) + "***"
        }
    }
}
