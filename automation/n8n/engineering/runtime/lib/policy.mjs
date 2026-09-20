export class PolicyEngine {
  constructor({ commandPolicy, roles, controls }) {
    this.commandPolicy = commandPolicy;
    this.roles = roles;
    this.controls = controls;
  }
  authorize({ role, action, environment, mode = 'pilot' }) {
    if (!this.controls.engineeringEnabled) throw new Error('engineering_killed');
    if (!this.controls.roles?.[role]) throw new Error('role_killed');
    if (mode === 'qualification' && !this.controls.qualificationEnabled) throw new Error('qualification_killed');
    if (mode === 'pilot' && !this.controls.pilotEnabled) throw new Error('pilot_gate_closed');
    if (!this.roles.environmentAllowlist.includes(environment) || environment === 'production') throw new Error('environment_denied');
    const rolePolicy = this.roles.roles[role];
    if (!rolePolicy) throw new Error('unknown_role');
    const actionPolicy = this.commandPolicy.actions[action];
    if (!actionPolicy?.enabled || !actionPolicy.roles.includes(role) || !rolePolicy.actions.includes(action)) throw new Error('action_denied');
    if (rolePolicy.denied.some((pattern) => pattern === action || (pattern.endsWith('.*') && action.startsWith(pattern.slice(0, -1))))) throw new Error('explicitly_denied');
    return actionPolicy;
  }
}
