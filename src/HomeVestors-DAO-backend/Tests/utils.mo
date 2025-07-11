import TestTypes "testTypes";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
module {
    type Callers = TestTypes.Callers;
    public func daysInFuture(days: Int): Int {
        Time.now() + days * 24 * 60 * 60 * 1_000;
    };

    public func getCallers(): Callers {
        {
            anon = Principal.fromText("2vxsx-fae");
            tenant1 = Principal.fromText("2e7fg-mfyxt-iivfx-l7pim-ysvwq-qetwz-h4rhz-t76tr-5zob4-oopr3-hae");
            tenant2 = Principal.fromText("fdiem-i5wk4-rm5ln-2jctb-zn7b7-wy6qb-vga36-7wodq-4clo4-5ewbb-5qe");
            admin = Principal.fromText("vq2za-kqaaa-aaaas-amlvq-cai");
        }
    };
}