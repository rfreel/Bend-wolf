import Base
import ./Logic.bend as L
import ./Rewrite.bend as R

# Exhaustive Boolean comparison is a finite check, not a universal proof.
def check(n: Nat, before: L.Expr, after: L.Expr) -> L.Outcome:
  L.equivalent(n, before, after)

# An unsatisfiable condition yields Equivalent vacuously; callers should check it.
def under(n: Nat, condition: L.Expr, before: L.Expr, after: L.Expr) -> L.Outcome:
  L.equivalence_result(L.satisfy(n, L.EAnd{condition, L.EXor{before, after}}))

# A compact finite truth-table certificate, checked against both inputs.
type TruthCertificate is Data:
  TruthCertificate{domain: Nat, bits: U32}

type CertificateResult is Data:
  CertificateInvalid{}
  CertificateRejected{}
  CertificateAccepted{}

def certificate_decision(ok: Bool) -> CertificateResult:
  match ok:
    case True{}: CertificateAccepted{}
    case False{}: CertificateRejected{}

def certificate_compare(n: Nat, certificate: TruthCertificate, left: R.KeyResult, right: R.KeyResult) -> CertificateResult:
  match certificate left right:
    case TruthCertificate{domain, +bits} R.TruthKey{a} R.TruthKey{b}:
      certificate_decision(Bool.and(Nat.is_eq(n, domain), Bool.and(U32.is_eq(bits, a), U32.is_eq(bits, b))))
    case _ _ _: CertificateInvalid{}

def verify_certificate(+n: Nat, left: L.Expr, right: L.Expr, certificate: TruthCertificate) -> CertificateResult:
  certificate_compare(n, certificate, R.truth_table(n, left), R.truth_table(n, right))
