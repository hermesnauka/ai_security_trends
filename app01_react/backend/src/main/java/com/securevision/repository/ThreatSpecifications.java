package com.securevision.repository;

import com.securevision.entity.Framework;
import com.securevision.entity.Severity;
import com.securevision.entity.Threat;
import jakarta.persistence.criteria.Join;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.util.StringUtils;

/**
 * Filter predicates backing GET /api/v1/threats (frameworkCode, severity, stride, tag, q).
 * `stride` and `tag` filter with a LIKE against the comma-joined column - acceptable for
 * Phase 1 data volume; revisit with a normalized join table if the card catalogue (Phase 6+)
 * makes this a hot path.
 */
public final class ThreatSpecifications {

    private ThreatSpecifications() {
    }

    public static Specification<Threat> hasFrameworkCode(String frameworkCode) {
        return (root, query, cb) -> {
            if (!StringUtils.hasText(frameworkCode)) {
                return cb.conjunction();
            }
            Join<Threat, Framework> frameworkJoin = root.join("framework");
            return cb.equal(cb.upper(frameworkJoin.get("code")), frameworkCode.toUpperCase());
        };
    }

    public static Specification<Threat> hasSeverity(Severity severity) {
        return (root, query, cb) -> {
            if (severity == null) {
                return cb.conjunction();
            }
            return cb.equal(root.get("severity"), severity);
        };
    }

    public static Specification<Threat> hasStride(String strideLetter) {
        return (root, query, cb) -> {
            if (!StringUtils.hasText(strideLetter)) {
                return cb.conjunction();
            }
            return cb.like(root.get("stride"), "%" + strideLetter.toUpperCase() + "%");
        };
    }

    public static Specification<Threat> hasTag(String tag) {
        return (root, query, cb) -> {
            if (!StringUtils.hasText(tag)) {
                return cb.conjunction();
            }
            return cb.like(cb.lower(root.get("tags")), "%" + tag.toLowerCase() + "%");
        };
    }

    public static Specification<Threat> textSearch(String q) {
        return (root, query, cb) -> {
            if (!StringUtils.hasText(q)) {
                return cb.conjunction();
            }
            String pattern = "%" + q.toLowerCase() + "%";
            return cb.or(
                    cb.like(cb.lower(root.get("title")), pattern),
                    cb.like(cb.lower(root.get("description")), pattern)
            );
        };
    }
}
