package com.liveplan.core.error

/**
 * Application error types
 * Aligned with iOS AppCore error handling
 */
sealed class AppError : Exception() {

    // ─────────────────────────────────────
    // Domain Errors
    // ─────────────────────────────────────

    /**
     * Input validation failed
     */
    data class ValidationError(override val message: String) : AppError()

    /**
     * Entity not found
     */
    data class NotFoundError(val entityType: String, val id: String) : AppError() {
        override val message: String = "$entityType not found: $id"
    }

    /**
     * Empty title error
     */
    data object EmptyTitleError : AppError() {
        override val message: String = "Title must not be empty"
    }

    /**
     * No task to complete
     */
    data object NoTaskToCompleteError : AppError() {
        override val message: String = "No task to complete"
    }

    /**
     * Duplicate completion error
     */
    data class DuplicateCompletionError(val taskId: String, val occurrenceKey: String) : AppError() {
        override val message: String = "Task $taskId already completed for $occurrenceKey"
    }

    /**
     * Circular dependency detected
     */
    data class CircularDependencyError(val taskIds: List<String>) : AppError() {
        override val message: String = "Circular dependency detected: $taskIds"
    }

    // ─────────────────────────────────────
    // Storage Errors
    // ─────────────────────────────────────

    /**
     * Storage operation failed
     */
    data class StorageError(override val cause: Throwable) : AppError() {
        override val message: String = "Storage error: ${cause.message}"
    }

    /**
     * Migration failed
     */
    data class MigrationError(val fromVersion: Int, val toVersion: Int) : AppError() {
        override val message: String = "Migration failed: $fromVersion → $toVersion"
    }

    // ─────────────────────────────────────
    // Unexpected Errors
    // ─────────────────────────────────────

    /**
     * Unexpected error wrapper
     */
    data class UnexpectedError(override val cause: Throwable) : AppError() {
        override val message: String = "Unexpected error: ${cause.message}"
    }
}
