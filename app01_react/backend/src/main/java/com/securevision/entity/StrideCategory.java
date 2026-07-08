package com.securevision.entity;

/**
 * The six STRIDE threat categories. See wiki concept "STRIDE Threat Modeling"
 * for the full definitions this schema is derived from.
 */
public enum StrideCategory {
    S, // Spoofing
    T, // Tampering
    R, // Repudiation
    I, // Information Disclosure
    D, // Denial of Service
    E  // Elevation of Privilege
}
