module ModelStruct

using DJUICE
using Test
using MAT

@testset "Model basic sturct" begin
	md = model()
	@test (typeof(md.mesh)) <: DJUICE.AbstractMesh
	@test (typeof(md.mesh)) == DJUICE.Mesh2dTriangle
	@test (typeof(md.friction)) <: DJUICE.AbstractFriction
	@test (typeof(md.friction)) <: DJUICE.BuddFriction

	md = model(md; friction=DNNFriction())
	@test (typeof(md.friction)) == DJUICE.DNNFriction

	md = model(md; friction=SchoofFriction())
	@test (typeof(md.friction)) == DJUICE.SchoofFriction
end

@testset "Enums <-> String" begin
	@test DJUICE.StringToEnum("FrictionCoefficient") == DJUICE.FrictionCoefficientEnum
	@test DJUICE.StringToEnum("MaterialsRheologyB") == DJUICE.MaterialsRheologyBEnum
	@test DJUICE.EnumToString(DJUICE.FrictionCoefficientEnum) == "FrictionCoefficient"
	@test DJUICE.EnumToString(DJUICE.MaterialsRheologyBEnum) == "MaterialsRheologyB"
end

@testset "Triangle" begin
	md = model()
	c = DJUICE.ExpStruct()
	c.name = "domainoutline"
	c.nods = 5
	c.density = 1.0
	c.x = [0.0, 1.0e6, 1.0e6, 0.0, 0.0]
	c.y = [0.0, 0.0, 1.0e6, 1.0e6, 0.0]
	c.closed = true
	contour = [c]
	md = triangle(md,contour,50000.) 
	@test md.mesh.numberofvertices == 340
	@test md.mesh.numberofelements == 614
end

end
