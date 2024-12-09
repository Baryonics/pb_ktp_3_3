module Reichweiten
using Plots, CSV, DataFrames, LsqFit, Statistics, Roots, FilePathsBase, Revise
using ..EasyLinearRegression
export plot_p_counts, Result, plot_p_over_1_d, print_result, plot_p_U




struct Result
    p::Float64
    D_p::Float64
    fit_params::Vector{Float64}
    D_fit_params::Vector{Float64}
    d::Float64
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
    Delta_p_mean_dist = 0.5 * Delta_counts_per_second[2]
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

    result = Result(p_mean_dist, Delta_p_mean_dist, fit_params, Delta_fit_params, d)

    print_result(result)
    return result
end



function print_result(res::Result)
    println("Der Mittlere Druck ist: p = ", res.p, "+- " , res.D_p)
    println("Fit-Parameter: ")
    println("a = ", res.fit_params[1], " +- ", res.D_fit_params[1])
    println("b = ", res.fit_params[2], " +- ", res.D_fit_params[2])
    println("c = ", res.fit_params[3], " +- ", res.D_fit_params[3])
end



function plot_p_over_1_d(results_from_reichweiten::Vector{Result}, D_d::Float64)
    
    ### Extrahiere Ergebnisse ###
    p_means = Float64[]
    D_p_means = Float64[]
    fit_params = Vector{Float64}[]
    D_fit_params = Vector{Float64}[]
    ds = Float64[]

    for result::Result in results_from_reichweiten
        push!(p_means, result.p)
        push!(D_p_means, result.D_p)
        push!(fit_params, result.fit_params[:])
        push!(D_fit_params, result.D_fit_params[:])
        push!(ds, result.d)
    end


    # Fit-Funktion definieren (lineare Regression)
    fit_model(x, p) = p[1] * x .+ p[2]

    # Fit durchführen
    initial_params = [1.0, 1.0]  # Anfangsschätzungen für die Parameter
    fit_result = curve_fit(fit_model, 1 ./ p_means, ds, initial_params)
    fit_params = fit_result.param  # Angepasste Parameter (Steigung, Achsenabschnitt)

    # Berechne den Bereich für die Fit-Kurve (1/p_means)
    p_fit = range(minimum(1 ./ p_means), maximum(1 ./ p_means), length=100)  # Glatter Bereich
    fit_curve = fit_model(p_fit, fit_params)  # Berechne die Fit-Kurve mit den angepassten Parametern


    #Unsicherheiten der Fit-Parameter
    Delta_fit_params = standard_errors(fit_result)

    ### Plot wird hier erzeugt ###
    fig = plot(
        1 ./ p_means,
        ds,
        xerr = D_p_means ./ p_means.^2,  # Fehler in x
        yerr = D_d,  # Fehler in y
        seriestype = "scatter",
        xlabel = "1/p in 1/mbar",
        ylabel = "Abstand d in mm",
        label = "1/p inverser mittlerer Druck",
        ylims = (33, 38),  # Setze die y-Achsen-Grenzen
        title="Abstand d aufgetragen gegen den inversen Druck"
    )

    # Fit-Kurve hinzufügen
    plot!(
        p_fit,
        fit_curve,
        label = "Fit-Kurve",
        linewidth = 2,
        color = :red
    )


    r_mean = fit_params[1] / 1013
    D_r_mean = Delta_fit_params[1] / 1013


    println("Die Mittlere Reichweite in Luft beträgt: R = ", r_mean, " +- ", D_r_mean)
    println("Fit Paramter: ")
    println("a = ", fit_params[1], " +- ", Delta_fit_params[1])
    println("b = ", fit_params[2], " +- ", Delta_fit_params[2])

    path_to_plot_file = path_to_plots * "/" * "d_1_over_p" * ".png"
    savefig(fig,path_to_plot_file)

    display(fig)
    return r_mean, D_r_mean
end





function plot_p_U(csv_name, relevant_last_data_points)
    path_to_csv = path_to_data * "/" * csv_name
    data = CSV.read(path_to_csv, DataFrame)
    ps = data[:,1]
    Us = data[:,4]
    D_ps = data[:,2]
    D_Us = data[:,5]

    relevant_ps = ps[end-relevant_last_data_points:end]
    relevant_Us = Us[end-relevant_last_data_points:end]

    #Lineare Regression
    linreg = EasyLinearRegression.do_linreg(relevant_ps, relevant_Us)
    a = linreg.a
    b = linreg.b
    D_a = linreg.D_a
    D_b = linreg.D_b

    function fit_func(x)
        return a*x+b
    end


    p_mean = find_zero(fit_func, 1000.)
    D_p_mean = sqrt((p_mean*D_a)^2 + D_b^2)
    fig = plot(
        ps,
        Us,
        seriestype="scatter",
        xerror=D_ps,
        yerror=D_Us,
        title="Mittlere Impulshöhe aufgetragen gegen Druck",
        xlabel="Druck in [mbar]",
        ylabel="U in [V]", 
        label = "Messwerte",
        xlims=(-20,1050),
        ylims=(-5,90)
    )

    plot!(
        fit_func,
        label="Fit-Kurve",
        linewidth=2,
        color=:red
    )

    println("Gefittet mit den ", relevant_last_data_points, " letzen Datenpunkten")
    println("Fitparameter: ")
    println("a = ", a, " +- ", D_a)
    println("b = ", b, " +- ", D_b)
    println("\n")
    println("Mittlerer Druck: ")
    println("p = ", p_mean, " +- ", D_p_mean)

    path_to_plot_file = path_to_plots * "/" * csv_name * "_impuls" * ".png"
    savefig(fig,path_to_plot_file)

    display(fig)
end
end