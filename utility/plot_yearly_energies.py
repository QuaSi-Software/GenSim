"""
Plots yearly energies by two different mappings as bar chart.
"""
import pandas as pd
import matplotlib.pyplot as plt


def read_csv(filename):
    """Read the given CSV file and provide a pandas data frame for it."""
    df = pd.read_csv(filename)
    return df

def j_to_kwh(x):
    """Convert J to kWh."""
    return x / 3600000

def j_to_mwh(x):
    """Convert J to MWh."""
    return j_to_kwh(x) * 0.001

def w_to_kwh(x):
    """Convert W to kWh, using an implicit time of 1 h."""
    return x * 0.001

def w_to_mwh(x):
    """Convert W to MWh, using an implicit time of 1 h."""
    return w_to_kwh(x) * 0.001

def wh_to_mwh(x):
    """Convert Wh to MWh."""
    return x * 0.000001

def convert_units(df):
    """Convert the units in the given data frame to MWh for units J and W."""
    for column in df.columns:
        if "[J]" in column:
            df[column] = df[column].apply(j_to_mwh)
        elif "[Wh]" in column:
            df[column] = df[column].apply(wh_to_mwh)
        elif "[W]" in column:
            # conversion from power to energy works only with implicit time step of 1 h
            df[column] = df[column].apply(w_to_mwh)

    df.rename(columns=lambda c: c.replace('[J]', ''), inplace=True)
    df.rename(columns=lambda c: c.replace('[W]', ''), inplace=True)
    df.rename(columns=lambda c: c.replace('[Wh]', ''), inplace=True)
    df.rename(columns=lambda c: c.replace('[hr]', ''), inplace=True)


def create_barchart(
    title_name, block, mechanical_ventilation_losses, mechanical_ventilation_gains,
    transmission_trans_losses, transmission_opqaue_losses, transmission_trans_gains,
    transmission_opqaue_gains, infiltration_losses, infiltration_gains, window_ventilation_losses,
    window_ventilation_gains, solar_gains, internal_gains, heating_gains, cooling_losses
):
    """Creates a bar chart with the given values for the various gains and losses."""
    # create the comparison bar chart
    df = pd.DataFrame(
        columns=['Energy balance', 'Name', 'Value'],
        data=[
            ['Gains', 'Mechanical Ventilation', mechanical_ventilation_gains],
            ['Gains', 'Transmission Opaque', transmission_opqaue_gains],
            ['Gains', 'Transmission Transparent', transmission_trans_gains],
            ['Gains', 'Infiltration', infiltration_gains],
            ['Gains', 'Window Ventilation', window_ventilation_gains],
            ['Gains', 'Solar', solar_gains],
            ['Gains', 'Internal', internal_gains],
            ['Gains', 'Heating', heating_gains],
            ['Gains', 'Cooling', 0],
            ['Losses', 'Mechanical Ventilation', mechanical_ventilation_losses],
            ['Losses', 'Transmission Opaque', transmission_opqaue_losses],
            ['Losses', 'Transmission Transparent', transmission_trans_losses],
            ['Losses', 'Infiltration', infiltration_losses],
            ['Losses', 'Window Ventilation', window_ventilation_losses],
            ['Losses', 'Solar', 0],
            ['Losses', 'Internal', 0],
            ['Losses', 'Heating', 0],
            ['Losses', 'Cooling', cooling_losses]
        ]
    )

    colors = [
        (0.6509803921568628, 0.807843137254902, 0.8901960784313725),
        (0.12156862745098039, 0.47058823529411764, 0.7058823529411765),
        (0.6980392156862745, 0.8745098039215686, 0.5411764705882353),
        (0.2, 0.6274509803921569, 0.17254901960784313),
        (0.984313725490196, 0.6039215686274509, 0.6),
        (0.8901960784313725, 0.10196078431372549, 0.10980392156862745),
        (0.9921568627450981, 0.7490196078431373, 0.43529411764705883),
        (1.0, 0.4980392156862745, 0.0),
        (0.792156862745098, 0.6980392156862745, 0.8392156862745098),
        (0.41568627450980394, 0.23921568627450981, 0.6039215686274509),
        (1.0, 1.0, 0.6),
        (0.6941176470588235, 0.34901960784313724, 0.1568627450980392)
    ]
    ax = df.groupby(['Energy balance', 'Name']).sum().unstack().plot(
        kind='bar', stacked=True, width=0.99, color=colors
    )
    ax.legend(
        [
            'Cooling', 'Heating', 'Infiltration', 'Internal', 'Mechanical Ventilation', 'Solar',
            'Transmission Opaque', 'Transmission Transparent', 'Window Ventilation'
        ],
        bbox_to_anchor=(1.05, 1.0),
        loc='upper left'
    )
    ax.set_title(title_name)
    ax.set_ylabel("MWh")
    plt.tight_layout()
    plt.show(block=block)

def try_first(df, key):
    """Returns the first value of the given column, if it exists, with 0 otherwise."""
    try:
        val = df.at[0, key]
        return val
    except KeyError:
        return 0

def create_plot(df):
    """Create a plot for comparison two mappings as bar charts from the given data frame."""

    convert_units(df)

    # old mapping
    mechanical_ventilation_losses = try_first(df, "METER MECHANICAL VENTILATION HEAT LOSS")
    mechanical_ventilation_gains = 0
    transmission_trans_losses = try_first(df, "METER WINDOW CONDUCTION HEAT LOSS")
    transmission_opaque_losses = try_first(df,
        "METER SURFACE AVERAGE FACE CONDUCTION HEAT LOSS RATE")
    transmission_trans_gains = try_first(df, "METER WINDOW CONDUCTION HEAT GAIN")
    transmission_opaque_gains = try_first(df,
        "METER SURFACE AVERAGE FACE CONDUCTION HEAT GAIN RATE")
    infiltration_losses = 0
    infiltration_gains = 0
    window_ventilation_losses = 0
    window_ventilation_gains = 0
    solar_gains = (try_first(df, "METER ZONE WINDOWS TOTAL TRANSMITTED SOLAR RADIATION ENERGY")
        - try_first(df, "METER WINDOW CONDUCTION HEAT GAIN"))
    internal_gains = (try_first(df, "METER PEOPLE HEAT GAIN")
        + try_first(df, "METER LIGHTS HEAT GAIN")
        + try_first(df, "METER PEOPLE HEAT GAIN"))
    heating_gains = try_first(df, "METER HEATING")
    cooling_losses = try_first(df, "METER COOLING")

    create_barchart("Old Mapping", False, mechanical_ventilation_losses,
        mechanical_ventilation_gains, transmission_trans_losses, transmission_opaque_losses,
        transmission_trans_gains, transmission_opaque_gains, infiltration_losses,
        infiltration_gains, window_ventilation_losses, window_ventilation_gains, solar_gains,
        internal_gains, heating_gains, cooling_losses
    )

    # new mapping
    mechanical_ventilation_losses = try_first(df, "METER MECHANICAL VENTILATION HEAT LOSS")
    mechanical_ventilation_gains = 0
    transmission_trans_losses = try_first(df, "METER WINDOW CONDUCTION HEAT LOSS")
    transmission_opaque_losses = try_first(df, "METER WALL CONDUCTION HEAT LOSS")
    transmission_trans_gains = 0
    transmission_opaque_gains = try_first(df, "METER WALL CONDUCTION HEAT GAIN")
    infiltration_losses = try_first(df, "METER INFILTRATION HEAT LOSS")
    infiltration_gains = try_first(df, "METER INFILTRATION HEAT GAIN")
    window_ventilation_losses = try_first(df, "METER WINDOW VENTILATION HEAT LOSS")
    window_ventilation_gains = try_first(df, "METER WINDOW VENTILATION HEAT GAIN")
    solar_gains = try_first(df, "METER WINDOW TOTAL HEAT GAIN")
    internal_gains = (try_first(df, "METER PEOPLE HEAT GAIN")
        + try_first(df, "METER LIGHTS HEAT GAIN")
        + try_first(df, "METER ELECTRIC EQUIPMENT HEAT GAIN"))
    heating_gains = try_first(df, "METER HEATING")
    cooling_losses = try_first(df, "METER COOLING")

    create_barchart("New Mapping", True, mechanical_ventilation_losses,
        mechanical_ventilation_gains, transmission_trans_losses, transmission_opaque_losses,
        transmission_trans_gains, transmission_opaque_gains, infiltration_losses,
        infiltration_gains, window_ventilation_losses, window_ventilation_gains, solar_gains,
        internal_gains, heating_gains, cooling_losses
    )

def main():
    """Entry point to the script."""
    csv_filename = './Output/reports/results_report_variables_ZoneTimestep-Sum.csv'
    frame = read_csv(csv_filename)
    create_plot(frame)

main()
