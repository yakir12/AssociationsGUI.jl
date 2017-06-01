using AssociationsGUI, Base.Dates
using Base.Test


@testset "util" begin 

    @test AssociationsGUI.second2hms(Second(59)) == Dict(Hour => 0, Minute => 0, Second => 59)
    @test AssociationsGUI.second2hms(Second(60 + 1)) == Dict(Hour => 0, Minute => 1, Second => 1)
    @test AssociationsGUI.second2hms(Second(60*60 + 1)) == Dict(Hour => 1, Minute => 0, Second => 1)
    @test AssociationsGUI.second2hms(Second(60*60*60)) == Dict(Hour => 60, Minute => 0, Second => 0)

    @test length(AssociationsGUI.shorten("1234567", 3)) == 7
    @test length(AssociationsGUI.shorten("1234567", 2)) == 5

    @test AssociationsGUI.findshortfile("aaa", Dict("aaa" => "b", "c" => "aaa")) == "c"
    @test_throws ErrorException AssociationsGUI.findshortfile("aaa", Dict("aaa" => "b", "c" => "aa")) == "c"

    t = (1977, 06, 01, 12, 0, 1)
    d1 = AssociationsGUI.validargs(:a, t...)
    @test isnull(d1)

    t = (1977, 02, 31, 12, 0, 1)
    d2 = AssociationsGUI.validargs(:a, t...)
    @test !isnull(d2)

end
