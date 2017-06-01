using AssociationsGUI, Base.Dates
using Base.Test


@testset "util" begin 

    @test AssociationsGUI.second2hms(Second(59)) == Dict(Hour => 0, Minute => 0, Second => 59)
    @test AssociationsGUI.second2hms(Second(60 + 1)) == Dict(Hour => 0, Minute => 1, Second => 1)
    @test AssociationsGUI.second2hms(Second(60*60 + 1)) == Dict(Hour => 1, Minute => 0, Second => 1)
    @test AssociationsGUI.second2hms(Second(60*60*60)) == Dict(Hour => 60, Minute => 0, Second => 0)

    @test length(AssociationsGUI.shorten("1234567", 3)) == 7
    @test length(AssociationsGUI.shorten("1234567", 2)) == 5

end
