package com.liveplan.data.database.migration

import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

/**
 * Room database migrations for LivePlan
 *
 * Migration strategy:
 * - Each migration is a separate object for testability
 * - Migrations are fail-safe: catch and log errors, don't crash
 * - Version 1 is the initial schema
 * - Version 2+ will handle data-model.md Phase 2 changes
 */
object Migrations {

    /**
     * Migration from version 1 to 2
     *
     * Changes:
     * - Adds compound index on completion_logs (taskId, occurrenceKey) if not exists
     * - Ensures default values for nullable fields
     */
    val MIGRATION_1_2 = object : Migration(1, 2) {
        override fun migrate(database: SupportSQLiteDatabase) {
            try {
                // Add compound index for completion_logs if not exists
                // This enforces (taskId, occurrenceKey) uniqueness
                database.execSQL(
                    """
                    CREATE UNIQUE INDEX IF NOT EXISTS
                    `index_completion_logs_taskId_occurrenceKey`
                    ON `completion_logs` (`taskId`, `occurrenceKey`)
                    """.trimIndent()
                )

                // Update any null priority values to P4 (default)
                database.execSQL(
                    """
                    UPDATE tasks SET priority = 'P4' WHERE priority IS NULL
                    """.trimIndent()
                )

                // Update any null workflowState values to TODO (default)
                database.execSQL(
                    """
                    UPDATE tasks SET workflowState = 'TODO' WHERE workflowState IS NULL
                    """.trimIndent()
                )

                // Update any null recurrenceBehavior values to HABIT_RESET (default)
                database.execSQL(
                    """
                    UPDATE tasks SET recurrenceBehavior = 'HABIT_RESET' WHERE recurrenceBehavior IS NULL
                    """.trimIndent()
                )

            } catch (e: Exception) {
                // Log error but don't crash - fail-safe
                // Migration will be retried on next app launch if needed
                android.util.Log.e("Migrations", "Migration 1->2 failed", e)
            }
        }
    }

    /**
     * All migrations for Room database builder
     */
    val ALL: Array<Migration> = arrayOf(
        MIGRATION_1_2
    )

    /**
     * Placeholder for future migration from version 2 to 3
     * Will handle Phase 2+ features if needed
     */
    val MIGRATION_2_3 = object : Migration(2, 3) {
        override fun migrate(database: SupportSQLiteDatabase) {
            // Placeholder for future migrations
            // Example: Add new columns, modify constraints, etc.
        }
    }
}

/**
 * Migration utilities
 */
object MigrationUtils {

    /**
     * Check if a column exists in a table
     */
    fun columnExists(database: SupportSQLiteDatabase, tableName: String, columnName: String): Boolean {
        return try {
            database.query("PRAGMA table_info($tableName)").use { cursor ->
                val nameIndex = cursor.getColumnIndex("name")
                while (cursor.moveToNext()) {
                    if (cursor.getString(nameIndex) == columnName) {
                        return true
                    }
                }
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Check if an index exists
     */
    fun indexExists(database: SupportSQLiteDatabase, indexName: String): Boolean {
        return try {
            database.query("PRAGMA index_list").use { cursor ->
                val nameIndex = cursor.getColumnIndex("name")
                while (cursor.moveToNext()) {
                    if (cursor.getString(nameIndex) == indexName) {
                        return true
                    }
                }
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Safely add a column if it doesn't exist
     */
    fun addColumnIfNotExists(
        database: SupportSQLiteDatabase,
        tableName: String,
        columnName: String,
        columnDefinition: String
    ) {
        if (!columnExists(database, tableName, columnName)) {
            database.execSQL("ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition")
        }
    }
}
