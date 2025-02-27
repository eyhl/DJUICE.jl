using Enzyme

#using Optimization, OptimizationOptimJL

function Control_Core(md::model, femmodel::FemModel)
	#independent variable
	α = md.inversion.independent
	#initialize derivative as 0
	∂J_∂α = zero(α)
	if md.inversion.onlygrad
		# only compute the gradient
		ComputeGradient(∂J_∂α, α, femmodel)
		#Put gradient in results
		InputUpdateFromVectorx(femmodel, ∂J_∂α, GradientEnum, VertexSIdEnum)
		RequestedOutputsx(femmodel, [GradientEnum])
	else
		# optimization
		# use user defined grad, errors!
		#		optprob = OptimizationFunction(costfunction, Optimization.AutoEnzyme())
		#		prob = Optimization.OptimizationProblem(optprob, α, femmodel, lb=md.inversion.min_parameters, ub=md.inversion.max_parameters)
		#		sol = Optimization.solve(prob, Optim.LBFGS())
		independent_enum = StringToEnum(md.inversion.independent_string)
		InputUpdateFromVectorx(femmodel, sol.u, independent_enum, VertexSIdEnum)
		RequestedOutputsx(femmodel, [independent_enum])
	end
end#}}}

function ComputeGradient(∂J_∂α::Vector{Float64}, α::Vector{Float64}, femmodel::FemModel) #{{{
	# zero ALL depth of the model, make sure we get correct gradient
	dfemmodel = Enzyme.Compiler.make_zero(Base.Core.Typeof(femmodel), IdDict(), femmodel)
	# compute the gradient
	autodiff(set_runtime_activity(Enzyme.Reverse), costfunction, Active, Duplicated(α, ∂J_∂α), Duplicated(femmodel,dfemmodel))
end#}}}
function CostFunctionx(femmodel::FemModel, α::Vector{Float64}, controlvar_enum::IssmEnum, SId_enum::IssmEnum, cost_enum_list::Vector{IssmEnum}, ::Val{solutionstring}) where solutionstring #{{{
	#Update FemModel accordingly
	InputUpdateFromVectorx(femmodel, α, controlvar_enum, SId_enum)

	#solve PDE
	if(solutionstring===:StressbalanceSolution)
		analysis = StressbalanceAnalysis()
	elseif (solutionstring===:TransientSolution)
		analysis = TransientAnalysis()
	else
		error("not supported")
	end

	Core(analysis, femmodel)

	#update all values of the cost functions
	RequestedOutputsx(femmodel, cost_enum_list)

	#Compute cost function
	J = 0.0
	for i in 1:length(cost_enum_list)
		J += femmodel.results[end-i+1].value
	end

	#return cost function
	return J
end#}}}

# cost function handler for autodiff
function costfunction(α::Vector{Float64}, femmodel::FemModel) #{{{
	# get the md.inversion.independent_string
	control_string = FindParam(String, femmodel.parameters, InversionControlParametersEnum)
	# get the Enum
	controlvar_enum = StringToEnum(control_string)
	if isnothing(controlvar_enum)
		error(control_string, " is not defined in DJUICE, therefore the derivative with respect to ", control_string, " is meaningless")
	end

	# get the cost function list from md.inversion.dependent_string
	cost_list = FindParam(Vector{String}, femmodel.parameters, InversionCostFunctionsEnum)
	cost_enum_list = Vector{IssmEnum}(undef, length(cost_list))
	for (index, value) in enumerate(cost_list)
		cost_enum_list[index] = StringToEnum(value)
	end

	# compute cost function
	# TODO: loop through all controls with respect to all the components in the cost function
	solutionstring = FindParam(Symbol, femmodel.parameters, SolutionTypeEnum)
	CostFunctionx(femmodel, α, controlvar_enum, VertexSIdEnum, cost_enum_list, Val(solutionstring))
end#}}}
