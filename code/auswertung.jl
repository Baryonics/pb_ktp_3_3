include("reichweiten_mod.jl")
using .Reichweiten

function reichweiten()
    csv_names_OF = ["d1.csv", "d2.csv", "d3.csv", "d4.csv"]
    d_OF = [34.0, 35.0, 36.0, 37.0]
    p_OF = zeros(4)
    Delta_p_OF = zeros(4)
    fit_params_OF = zeros(4)
    Delta_fit_params_OF = zeros(4)
    
    d_1_res = plot_p_counts(csv_names_OF[1], 750.0, d_OF[1])
    
end


function main()
    reichweiten()
end


main()