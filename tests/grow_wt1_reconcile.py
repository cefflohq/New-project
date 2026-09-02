from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
VENDOR = (ROOT / "vendor/index.html").read_text()
BACKEND = (ROOT / "vendor/backend.js").read_text()
RIDER = (ROOT / "rider/index.html").read_text()


class GrowWt1ReconcileTests(unittest.TestCase):
    def test_zone_management_is_reachable(self):
        self.assertIn("zones: pageZones", VENDOR)
        self.assertIn("data-action=\"confirmCreateZone\"", VENDOR)
        self.assertIn("ACTIONS.confirmCreateZone = async function", BACKEND)
        self.assertIn("api.rpc('create_zone'", BACKEND)

    def test_zone_assignment_uses_authoritative_run_contract(self):
        handler = BACKEND.split("ACTIONS.assignZoneRider = async function", 1)[1].split("ACTIONS.", 1)[0]
        self.assertIn("buildRiderRun", handler)
        self.assertIn("hydrateCanonicalWorkspace", handler)
        self.assertNotIn("CEFFLO_ENGINE", handler)
        self.assertNotIn("Rider assigned successfully", handler)

    def test_quick_add_rider_bypass_is_removed(self):
        self.assertNotIn("function inviteRiderCommand", VENDOR)
        self.assertNotIn("commands.inviteRider", VENDOR)
        self.assertNotIn('data-action="confirmInviteRider"', VENDOR)
        self.assertIn("create_rider_invitation", BACKEND)
        self.assertIn("ACTIONS.confirmInviteRiderReal", BACKEND)

    def test_real_delivery_events_are_hydrated(self):
        self.assertIn("listDeliveryEvents", BACKEND)
        self.assertIn("delivery.issue_reported", BACKEND)
        self.assertNotRegex(BACKEND, r"state\.issues\s*=\s*\[\]\s*;")
        self.assertNotRegex(BACKEND, r"state\.orderStatusHistory\s*=\s*\[\]\s*;")

    def test_random_proximity_claim_is_removed(self):
        self.assertNotIn("Math.random()<0.18", RIDER)
        arrive = RIDER.split("function arriveAtStop()", 1)[1].split("function renderArrivedPod", 1)[0]
        self.assertNotIn("far_location", arrive)

    def test_no_direct_table_mutation_was_added(self):
        self.assertNotRegex(BACKEND, r"/rest/v1/(zones|orders|rider_assignments).*method\s*:\s*['\"](?:POST|PATCH|DELETE)")


if __name__ == "__main__":
    unittest.main()
