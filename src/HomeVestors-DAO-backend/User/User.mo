import Types "../Utils/types";
import Result "mo:base/Result";

module {
    type User = Types.User;
    type Vault = Types.Vault;
    type StabilityPosition = Types.StabilityPosition;
    type Globals = Types.Globals;
    type UpdateError = Types.UpdateError;
    type AllStablecoinWhats = Types.AllStablecoinWhats;
    type Arg<P> = Types.Arg<P, AllStablecoinWhats>;
    type UpdateResult = Types.UpdateResult;

    public func addUser(p: Principal, globals: Globals): User {
        let newUser = createNewUser(p);
        globals.users.put(p, newUser);
        newUser;
    };

    public func createNewUser(p: Principal): User {
      {
        id = p;
        vault = createVault();
        stabilityPosition = createStabilityPosition();
        transactionHistory = [];
        kyc = false;
        notifications = [];
        results = [];
        saved = [];
      }
    };

    func createVault(): Vault {
      {
        nftCollateral = [];
        hvrCollateral = 0;
        husdDebt = 0;
      }
    };

    func createStabilityPosition(): StabilityPosition {
      {
        depositedHUSD = 0;
        pendingHVRRewards = 0;
        pendingNFTRewards = [];
        lastReward = 0;
      }
    };

    public func removeProperty(p: Principal, globals: Globals): Result.Result<User, UpdateError> {
        switch(globals.users.remove(p)){
            case(null){
                return #err(#InvalidUserPrincipal);
            };
            case(?u){
                return #ok(u);
            }
        }
    };

    public func updateProperty(arg: Arg<User>): async UpdateResult {
        switch(arg.what){
            case(_) return #Err([(null, #InvalidParent)]);
        }
    };


}