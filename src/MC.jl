module MC

export RV, ArrayRV, sample

import Base
using Base.Iterators: product

# Random Variables
abstract type RV end

struct ArrayRV <: RV
    variates
end

sample(rv::ArrayRV) = rv.variates

# Expressions of Random Variables
struct NExpr{N}
    rvs::NTuple{N, RV}
    f
end

apply(f, rvs::RV...) = NExpr(rvs, f)
apply(f, ex::NExpr) = apply(f ∘ ex.f, ex.rvs)
Base.in(rv::RV, ex::NExpr) = any(rv === exrv for exrv in ex.rvs)

struct ProductSample end

function sample_rvs(ex::NExpr, ::ProductSample)
    variates = map(sample, ex.rvs)
    @debug variates
    n_out = *(length.(variates)...)
    @debug n_out
    reshape(collect(product(variates...)), n_out), n_out
end

function sample(ex::NExpr{N}, method=ProductSample()) where N
    variates, n_out = sample_rvs(ex, method)
    sample(ex.f, variates, n_out)
end

function sample(f, variates, n_out)
    outtype = typeof(f(first(variates)...))
    out = Array{outtype}(undef, n_out)
    i = 1
    for x in variates
        out[i] = f(x...)
        i += 1
        (i > n_out) && break
    end
    out
end

function find(rv::RV, ex::NExpr)
    for i in eachindex(ex.rvs)
        (rv === ex.rvs[i]) && return i
    end
    return nothing
end

function merge_indexes(ex1::NExpr{N1}, ex2::NExpr{N2}) where {N1, N2}
    idx = zeros(Int, N2)
    k = 1
    for j in eachindex(ex2.rvs)
        i = find(ex2.rvs[j], ex1)
        if i === nothing
            idx[j] = N1 + k
            k += 1
        else
            idx[j] = i
        end
    end
    idx
end

function apply(f, ex1::NExpr{N1}, ex2::NExpr{N2}) where {N1, N2}
    rightkept = [rv for rv in ex2.rvs if rv ∉ ex1]
    rightapply = merge_indexes(ex1, ex2)
    unique_rvs = tuple(ex1.rvs..., rightkept...)
    NExpr(
    unique_rvs,
    (x...) -> f(
        ex1.f([x[i] for i in eachindex(ex1.rvs)]...),
        ex2.f([x[i] for i in rightapply]...)))
end

Base.convert(::Type{<:NExpr}, x::RV) = apply(x -> x, x)
Base.promote_rule(::Type{<:NExpr{N}}, ::Type{<:RV}) where N = NExpr{N}

# Define basic unary operators.
for op in (:+, :-, :!)
    @eval Base.$op(x::Union{NExpr, RV}) = apply(x -> $op(x), x)
end

# Define basic binary operators.
for op in (:+, :-, :/, :*)
    @eval function Base.$op(x::Union{NExpr, RV}, y::Union{NExpr, RV})
        apply((x, y) -> $op(x, y), promote(x, y)...)
    end
    @eval function Base.$op(x::Union{NExpr, RV}, y)
        apply(x -> $op(x, y), x)
    end
    @eval function Base.$op(x, y::Union{NExpr, RV})
        apply(y -> $op(x, y), y)
    end
end

# Sample for numbers so that sample can be called on RV or number.
sample(x::Number) = [x]

end # module
