module EasyLinearRegression
    export Linreg, do_linreg

    struct Linreg
        a::Float64
        b::Float64
        D_a::Float64
        D_b::Float64
    end

    function do_linreg(xs::Vector{Float64}, ys::Vector{Float64})
        if length(xs) != length(ys)
            println("xs und ys müssen gleich groß sein!")
            return 
        end

        N = length(xs)
        x = sum(xs)
        y = sum(ys)
        xx = sum(xs.^2)
        xy = sum(xs .* ys)
        Delta = N * xx - x * x

        a = (N*xy - x*y)/Delta
        b = (xx*y - x*xy)/Delta

        ys_of_xs = a .* xs .+ b
        Delta_ys_sq = 1/(N-2) * sum((ys_of_xs .- ys).^2)

        D_a = sqrt(Delta_ys_sq * N/Delta)
        D_b = sqrt(Delta_ys_sq * xx/Delta)

        return Linreg(a,b,D_a,D_b)
    end
    
end