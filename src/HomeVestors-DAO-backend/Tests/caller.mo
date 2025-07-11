import TestTypes "testTypes";
import Utils "utils";

module{
    type Callers = TestTypes.Callers;
    type TestCase = TestTypes.TestCase; 

    public func getCaller(arg: TestCase): Principal {
        switch(arg){
            case(#Note(#Create(#AnonymousAuthor))) Utils.getCallers().anon;
            case(_) Utils.getCallers().admin;
        }
    };
}