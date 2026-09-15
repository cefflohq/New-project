from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
BACKEND = ROOT / "vendor" / "backend.js"


class VendorProtectedCutoverTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = BACKEND.read_text(encoding="utf-8")

    def test_all_batch_1_rpc_clients_are_exposed(self):
        for rpc in (
            "deactivate_rider",
            "update_rider_details",
            "update_order_details",
            "update_team_member",
            "reassign_rider",
            "update_business_profile",
        ):
            self.assertIn(f"api.rpc('{rpc}'", self.source)

    def test_existing_protected_flows_remain_rpc_backed(self):
        self.assertIn("api.rpc('create_delivery'", self.source)
        self.assertIn("api.rpc('assign_rider'", self.source)

    def test_active_handlers_are_replaced_by_protected_adapters(self):
        for handler in (
            "confirmAssignRiderOrder",
            "confirmDeactivateRider",
            "saveBusinessProfile",
        ):
            self.assertRegex(self.source, rf"ACTIONS\.{handler}\s*=\s*{handler}\s*;")

        self.assertRegex(
            self.source,
            r"if \(order\?\.riderId && order\.riderId !== el\.dataset\.riderid\) \{\s*"
            r"await reassignRider\(orderId, el\.dataset\.riderid\);",
        )
        self.assertIn("await deactivateRider(el.dataset.id);", self.source)
        self.assertIn("await updateBusinessProfile({", self.source)

    def test_active_adapter_has_no_direct_protected_table_mutation(self):
        mutation_request = re.compile(
            r"api\.request\([^\n]+(?:method\s*:\s*['\"](?:POST|PATCH|PUT|DELETE)['\"])",
            re.IGNORECASE,
        )
        self.assertIsNone(mutation_request.search(self.source))
        self.assertIn("syncOperationalStateToBackend = async () => true;", self.source)

    def test_rider_deactivation_preserves_existing_offline_ui_semantics(self):
        self.assertIn("row.status === 'inactive' ? 'offline' : row.status", self.source)


if __name__ == "__main__":
    unittest.main()
