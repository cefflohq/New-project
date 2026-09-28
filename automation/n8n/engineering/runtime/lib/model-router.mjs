export class ModelRouter {
  constructor(config, qualification = {}) {
    this.config = config;
    this.qualification = qualification;
  }
  qualifiedFor(role) {
    const required = this.config.requiredCapabilities[role] || [];
    return this.config.routes.filter((route) => {
      if (!route.rolesEligibleAfterQualification?.includes(role)) return false;
      if (route.provider === 'deterministic_runner') return role === 'E5';
      const result = this.qualification[route.routeId]?.roles?.[role];
      return result?.status === 'QUALIFIED' && required.every((cap) => result.capabilities?.includes(cap));
    }).sort((a, b) => this.#worstCaseUnitPrice(a) - this.#worstCaseUnitPrice(b));
  }
  select(role, { failedRouteId = null, classifiedFailure = null } = {}) {
    if (role === 'E5') return this.config.routes.find((r) => r.routeId === 'deterministic-e5');
    if (failedRouteId && !['capability', 'transport'].includes(classifiedFailure)) throw new Error('fallback_reason_invalid');
    const candidates = this.qualifiedFor(role).filter((r) => r.routeId !== failedRouteId);
    if (!candidates.length) throw new Error('no_qualified_route');
    return candidates[0];
  }
  #worstCaseUnitPrice(route) {
    const p = route.pricingUsdPerMillion;
    if (!p) return 0;
    return Math.max(p.input || 0, p.inputPeak || 0) + Math.max(p.output || 0, p.outputPeak || 0);
  }
}
