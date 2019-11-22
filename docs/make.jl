using Documenter, MC

makedocs(;
    modules=[MC],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/venuur/MC.jl/blob/{commit}{path}#L{line}",
    sitename="MC.jl",
    authors="Carl Morris",
    assets=String[],
)

deploydocs(;
    repo="github.com/venuur/MC.jl",
)
