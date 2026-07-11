package com.kotlinguard.data.db

import androidx.room.TypeConverter
import com.kotlinguard.data.model.CardKind
import com.kotlinguard.data.model.StrideCategory
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Room has no native column type for a `List<T>` or a `sealed interface` —
 * every non-primitive entity field is serialized to a single TEXT column via
 * these converters, using the same kotlinx.serialization `Json` instance
 * used everywhere else in `:data` (strict-by-default, D-06).
 */
class Converters {
    private val json = Json { encodeDefaults = true }

    @TypeConverter
    fun stringListToJson(value: List<String>): String = json.encodeToString(value)

    @TypeConverter
    fun jsonToStringList(value: String): List<String> = json.decodeFromString(value)

    @TypeConverter
    fun strideListToJson(value: List<StrideCategory>): String = json.encodeToString(value)

    @TypeConverter
    fun jsonToStrideList(value: String): List<StrideCategory> = json.decodeFromString(value)

    @TypeConverter
    fun cardKindToJson(value: CardKind): String = json.encodeToString(value)

    @TypeConverter
    fun jsonToCardKind(value: String): CardKind = json.decodeFromString(value)
}
