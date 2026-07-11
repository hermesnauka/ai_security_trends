<?php

declare( strict_types = 1 );

namespace SecurePress\PHPStan;

use PhpParser\Node;
use PhpParser\Node\Expr\StaticCall;
use PHPStan\Analyser\Scope;
use PHPStan\Rules\Rule;
use PHPStan\Rules\RuleErrorBuilder;

/**
 * D-03: SecurePress\Integrity\Integrity_Verifier::verify() may only be
 * called from the activation hook (SecurePress\Plugin) and from
 * SecurePress\Cron\Periodic_Reverify_Job. Fails analysis if any class under
 * the SecurePress\Rest_Api namespace references Integrity_Verifier at all —
 * this is the only enforcement mechanism for that boundary, since there is
 * no process or compiler boundary available in a single PHP-FPM plugin.
 *
 * @implements Rule<Node>
 */
final class NoIntegrityVerifierInRestApi implements Rule {

	private const FORBIDDEN_CLASS = 'SecurePress\\Integrity\\Integrity_Verifier';

	public function getNodeType(): string {
		return Node::class;
	}

	public function processNode( Node $node, Scope $scope ): array {
		if ( ! str_starts_with( (string) $scope->getClassReflection()?->getName(), 'SecurePress\\Rest_Api' ) ) {
			return array();
		}

		$references_forbidden_class = false;

		if ( $node instanceof StaticCall && $node->class instanceof Node\Name ) {
			$references_forbidden_class = ltrim( (string) $node->class, '\\' ) === self::FORBIDDEN_CLASS;
		} elseif ( $node instanceof Node\Stmt\Use_ ) {
			foreach ( $node->uses as $use ) {
				if ( ltrim( (string) $use->name, '\\' ) === self::FORBIDDEN_CLASS ) {
					$references_forbidden_class = true;
					break;
				}
			}
		}

		if ( ! $references_forbidden_class ) {
			return array();
		}

		return array(
			RuleErrorBuilder::message(
				'Classes under SecurePress\\Rest_Api must never reference Integrity_Verifier (PLAN.md D-03) — call it only from the activation hook or Periodic_Reverify_Job.'
			)->identifier( 'securepress.integrityVerifierIsolation' )->build(),
		);
	}
}
