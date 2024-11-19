using Plots, CSV, DataFrames, LsqFit, Statistics, Roots, Revise

module Reichweiten

export plot_p_counts, Result, plot_p_over_1_d

using Plots, CSV, DataFrames, LsqFit, Statistics, Roots, FilePathsBase

struct Result
    p::Float64
    D_p::Float64
    fit_params::Vector{Float64}
    D_fit_params::Vector{Float64}
end

path_to_plots = "../plots/"
path_to_data = "../data"


"""
# Die Funktion plottet Druck p gegen die Anzahl der Counts. Zusätzlich plottet sie einen geeigneten Fit
# Arguments
- `csv_name`: Name der .csv Datei
- `init_c_param`: Anfangsparameter für den Fit. Gibt an, an bei welchem Druck die Hälfte der maximalen Counts erreicht ist
- `d`: Gemessener Abstand 
- `init_a_param`: Anfangsparameter für den Fit. Maximalwert der Counts
- `init_b_param`: Anfangsparameter für den Fit. Gibt Steiheit der Kurve an
# return
- `p_fit`: Der Druck an dem die maximalen Counts um die Hälfte gesunken sind
- `half_max_counts`: Anzahl der halben maximalen counts
"""
function plot_p_counts(csv_name::String, init_c_param, d; time=60, init_a_param=60.0, init_b_param=0.5)
    # Daten einlesen
    path_to_csv = path_to_data * "/" * csv_name
    data = CSV.read(path_to_csv, DataFrame)
    p_s = data[:, 1]            # Druck in mbar
    counts = data[:, 3]
    counts_per_second = counts ./ time


    # Fit-Funktion definieren (z. B. eine exponentielle Funktion)
    fit_model(x, p) = p[1] ./ (1 .+ exp.(-p[2] .* (x .- p[3])))


    # Fit durchführen
    initial_params = [init_a_param, init_b_param, init_c_param]  # Anfangsschätzungen für die Parameter
    fit_result = curve_fit(fit_model, p_s, counts_per_second, initial_params)
    fit_params = fit_result.param


    # Fit-Werte berechnen
    p_fit = range(minimum(p_s), maximum(p_s), length=100)  # Glatter Bereich für die Fit-Kurve
    fit_curve = fit_model(p_fit, fit_params)


    # Finde die Mittlere Reichweite und dazugehörigen Druck
    m(x) = maximum(counts)/2/60
    function diff_fit_mean(x)
        fit_model(x,fit_params) - m(x)
    end
    p_mean_dist = find_zero(diff_fit_mean,init_c_param)


    # Fehler bestimmen
    Delta_counts_per_second = sqrt.(counts) ./ time
    Delta_p_s = data[:,2]
    Delta_p_mean_dist = 0.5 * Delta_counts_per_second[1]
    Delta_fit_params = standard_errors(fit_result)

    
    ### Plot wird hier Erzeugt ###
    # Plot erstellen
    fig = plot(
        p_s,
        counts_per_second,
        xlabel="Druck in mbar",
        ylabel="counts pro Sekunde",
        title="Counts pro Sekunde gegen Druck",
        seriestype="scatter",
        label="Messwerte",
        xerror=Delta_p_s,
        yerror=Delta_counts_per_second
    )

    # Fit-Kurve hinzufügen
    plot!(
        p_fit,
        fit_curve,
        label="Fit-Kurve",
        linewidth=2,
        color=:red
    )

    # Mittelwert Plotten
    plot!(
        m,
        label="Mean"
    )

    # Schnittpunkt plotten
    scatter!([p_mean_dist], [m(0)], label="Schnittpunkt", color=:green, marker=:circle, markersize=6)
    ### ###
    


    # Plot speichern
    path_to_plot_file = path_to_plots * "/" * csv_name * ".png"
    savefig(fig,path_to_plot_file)


    # Anzeigen des Plots
    display(fig)

    half_max_counts = m(0)

    result = Result(p_mean_dist, Delta_p_mean_dist, fit_params, Delta_fit_params)

    return result
end




function plot_p_over_1_d(results_from_reichweiten::Vector{Result})
    ### Extrahiere Ergebnisse ###
    p_means = zeros(0)
    D_p_means = zeros(0)
    fit_params = Vector{Vector{Float64}}[]
    D_fit_params = Vector{Vector{Float64}}[]

    for result::Result in results_from_reichweiten
        append!(p_means, result.p)
        append!(D_p_means, result.D_p)
        append!(fit_params, result.fit_params)
        append!(D_fit_params, result.D_fit_params)
    end

    @show fit_params
    
end




function plot_p_U(path_to_csv)
    data = CSV.read(path_to_csv, DataFrame)
    p_s = data[:,1]
    U = data[:,4]

    plot(
        p_s,
        U,
        seriestype="scatter"
    )
end


end