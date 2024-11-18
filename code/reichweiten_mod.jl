using Plots, CSV, DataFrames, LsqFit, Statistics, Roots

module Reichweiten

export plot_p_counts

using Plots, CSV, DataFrames, LsqFit, Statistics, Roots, FilePathsBase

path_to_plots = "../plots/"
path_to_data = "../data"


"""
# Die Funktion plottet Druck p gegen die Anzahl der Counts. Zusätzlich plottet sie einen geeigneten Fit
# Arguments
- `path_to_csv`: Der Pfad zur csv datei. Beginnt mit ../data/ 
- `init_c_param`: Anfangsparameter für den Fit. Gibt an, an bei welchem Druck die Hälfte der maximalen Counts erreicht ist
- `d`: Gemessener Abstand 
- `init_a_param`: Anfangsparameter für den Fit. Maximalwert der Counts
- `init_b_param`: Anfangsparameter für den Fit. Gibt Steiheit der Kurve an
"""
function plot_p_counts(csv_name::String, init_c_param, d; time=60, init_a_param=60.0, init_b_param=0.5)
    # Daten einlesen
    path_to_csv = path_to_data * "/" * csv_name
    data = CSV.read(path_to_csv, DataFrame)
    p_s = data[:, 1]            # Druck in mbar
    counts = data[:, 3]
    counts_per_second = counts ./ time


    # Fehler bestimmen
    Delta_counts_per_second = sqrt.(counts) ./ time
    Delta_p_s = data[:,2]

    # Fit-Funktion definieren (z. B. eine exponentielle Funktion)
    fit_model(x, p) = p[1] ./ (1 .+ exp.(-p[2] .* (x .- p[3])))

    # Fit durchführen
    initial_params = [60.0, 0.5, init_c_param]  # Anfangsschätzungen für die Parameter
    fit_result = curve_fit(fit_model, p_s, counts_per_second, initial_params)
    @show fit_params = fit_result.param

    # Fit-Werte berechnen
    p_fit = range(minimum(p_s), maximum(p_s), length=100)  # Glatter Bereich für die Fit-Kurve
    fit_curve = fit_model(p_fit, fit_params)


    # Funktion für mean
    m(x) = maximum(counts)/2/60

    # Funktion zum finden des Druckes
    function diff_fit_mean(x)
        fit_model(x,fit_params) - m(x)
    end

    p = find_zero(diff_fit_mean,init_c_param)
    println(p)

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
        m
    )

    # Schnittpunkt plotten
    scatter!([p], [m(0)], label="Schnittpunkt", color=:green, marker=:circle, markersize=6)

    

    # Plot speichern
    path_to_plot_file = path_to_plots * "/" * csv_name * ".png"
    savefig(fig,path_to_plot_file)

    display(fig)
    return 0
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