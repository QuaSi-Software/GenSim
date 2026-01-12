"""
Plots yearly energies by two different mappings as bar chart.
"""
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use("TkAgg")  # or "QtAgg" if you have PyQt/PySide installed

SIGN = {
    # HVAC (zone air system)
    "Zone Air System Sensible Heating Energy": +1,
   # "Zone Air System Sensible Cooling Energy": -1,

    # HVAC (terminal units)
    "Zone Air Terminal Sensible Heating Energy": +1,
    "Zone Air Terminal Sensible Cooling Energy": -1,

    # HVAC (radiant to surfaces)
    "Zone Radiant HVAC Heating Energy": +1,
    "Zone Radiant HVAC Cooling Energy": -1,

    # Internal gains
    "Zone People Sensible Heating Energy": +1,
    "Zone Lights Total Heating Energy": +1,
    "Zone Electric Equipment Total Heating Energy": +1,

    # Windows
    "Zone Windows Total Heat Gain Energy": +1,
    "Zone Windows Total Heat Loss Energy": -1,

    # Infiltration
    "Zone Infiltration Sensible Heat Gain Energy": +1,
    "Zone Infiltration Sensible Heat Loss Energy": -1,

    # Interzone air transfer
    "Zone Interzone Air Transfer Heat Gain Energy": +1,
    "Zone Interzone Air Transfer Heat Loss Energy": -1,

    # Opaque transmission
    "Zone Opaque Surface Inside Faces Total Conduction Heat Gain Energy": +1,
    "Zone Opaque Surface Inside Faces Total Conduction Heat Loss Energy": -1,
}



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

def wh_to_kwh(x):
    """Convert Wh to MWh."""
    return x * 0.001

def wh_to_mwh(x):
    """Convert Wh to MWh."""
    return x * 0.000001

def convert_units(df):
    """Convert the units in the given data frame to kWh for units J, Wh and W."""
    for column in df.columns:
        if "[J]" in column:
            df[column] = df[column].apply(j_to_kwh)
        elif "[Wh]" in column:
            df[column] = df[column].apply(wh_to_kwh)
        elif "[W]" in column:
            # conversion from power to energy works only with implicit time step of 1 h
            df[column] = df[column].apply(w_to_kwh)

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

def create_new_barchart(title, labels, values):
    import numpy as np
    import matplotlib.pyplot as plt

    vals = np.array(values, dtype=float)
    y = np.arange(len(labels))

    fig, ax = plt.subplots(figsize=(12, max(4, 0.35 * len(labels))))

    colors = ["tab:red" if v < 0 else "tab:blue" for v in vals]
    ax.barh(y, vals, color=colors)

    ax.set_yticks(y)
    ax.set_yticklabels(labels, fontsize=9)
    ax.set_title(title)
    ax.axvline(0)
    ax.set_xlabel("Energy (signed)")

    for i, v in enumerate(vals):
        ax.text(v, i, f" {v:,.3g}", va="center", fontsize=8)

    ax.grid(True, axis="x", linestyle="--", linewidth=0.5)
    plt.tight_layout()
    plt.show()

def signed_value(df, col):
    """
    Return signed value according to SIGN dictionary.
    Falls back to +1 if column is not explicitly listed.
    """
    if col not in df.columns:
        return 0.0
    return SIGN.get(col, +1) * try_first(df, col)

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
    mechanical_ventilation_losses = try_first(df,
        "METER ZONE MECHANICAL VENTILATION NO LOAD HEAT REMOVAL ENERGY")
    mechanical_ventilation_gains = 0
    transmission_trans_losses = try_first(df, "METER SURFACE WINDOW HEAT LOSS ENERGY")
    transmission_opaque_losses = try_first(df,
        "METER SURFACE AVERAGE FACE CONDUCTION HEAT LOSS RATE")
    transmission_trans_gains = try_first(df, "METER SURFACE WINDOW HEAT GAIN ENERGY")
    transmission_opaque_gains = try_first(df,
        "METER SURFACE AVERAGE FACE CONDUCTION HEAT GAIN RATE")
    infiltration_losses = 0
    infiltration_gains = 0
    window_ventilation_losses = 0
    window_ventilation_gains = 0
    solar_gains = (try_first(df, "METER ZONE WINDOWS TOTAL TRANSMITTED SOLAR RADIATION ENERGY")
        - try_first(df, "METER SURFACE WINDOW HEAT GAIN ENERGY"))
    internal_gains = (try_first(df, "METER PEOPLE HEAT GAIN")
        + try_first(df, "METER LIGHTS HEAT GAIN")
        + try_first(df, "METER PEOPLE HEAT GAIN"))
    heating_gains = try_first(df, "METER TOTAL HEATING")
    cooling_losses = try_first(df, "METER TOTAL COOLING")

    create_barchart("Old Mapping", False, mechanical_ventilation_losses,
        mechanical_ventilation_gains, transmission_trans_losses, transmission_opaque_losses,
        transmission_trans_gains, transmission_opaque_gains, infiltration_losses,
        infiltration_gains, window_ventilation_losses, window_ventilation_gains, solar_gains,
        internal_gains, heating_gains, cooling_losses
    )

    # new mapping
    mechanical_ventilation_losses = try_first(df, "METER MECHANICAL VENTILATION HEAT LOSS")
    mechanical_ventilation_gains = try_first(df, "METER MECHANICAL VENTILATION HEAT GAIN")
    transmission_trans_losses = try_first(df, "METER WINDOW CONDUCTION HEAT LOSS")
    transmission_opaque_losses = try_first(df, "Surface Inside Face Conduction Heat Loss Rate")
    transmission_trans_gains = try_first(df, "METER WINDOW CONDUCTION HEAT GAIN")
    transmission_opaque_gains = try_first(df, "Surface Inside Face Conduction Heat Gain Rate")
    infiltration_losses = try_first(df, "METER INFILTRATION HEAT LOSS")
    infiltration_gains = try_first(df, "METER INFILTRATION HEAT GAIN")
    window_ventilation_losses = try_first(df, "METER WINDOW VENTILATION HEAT LOSS")
    window_ventilation_gains = try_first(df, "METER WINDOW VENTILATION HEAT GAIN")
    solar_gains = try_first(df, "METER ZONE WINDOWS TOTAL TRANSMITTED SOLAR RADIATION ENERGY")
    internal_gains = (try_first(df, "METER PEOPLE HEAT GAIN")
        + try_first(df, "METER LIGHTS HEAT GAIN")
        + try_first(df, "METER ELECTRIC EQUIPMENT HEAT GAIN"))
    heating_gains = try_first(df, "METER TOTAL HEATING")
    cooling_losses = try_first(df, "METER TOTAL COOLING")

    create_barchart("New Mapping", True, mechanical_ventilation_losses,
        mechanical_ventilation_gains, transmission_trans_losses, transmission_opaque_losses,
        transmission_trans_gains, transmission_opaque_gains, infiltration_losses,
        infiltration_gains, window_ventilation_losses, window_ventilation_gains, solar_gains,
        internal_gains, heating_gains, cooling_losses
    )

import re
import re
import pandas as pd

def _strip_units(col: str) -> str:
    return re.sub(r"\s*\[[^\]]+\]\s*$", "", str(col)).strip()

def debug_lookup(df: pd.DataFrame, base_names):
    print("DF shape:", df.shape)
    print("First 20 columns:")
    for c in list(df.columns)[:20]:
        print("  -", repr(c))

    # Map base->actual
    base_to_actual = {}
    for c in df.columns:
        base_to_actual.setdefault(_strip_units(c), c)

    missing = []
    for base in base_names:
        actual = base_to_actual.get(base)
        if actual is None:
            missing.append(base)
        else:
            s = df[actual]
            # show numeric summary regardless of try_first
            print(f"\nFOUND: {base}  ->  {repr(actual)}")
            print("  dtype:", s.dtype)
            print("  head:", s.head(3).tolist())
            try:
                print("  sum:", float(pd.to_numeric(s, errors='coerce').sum()))
            except Exception as e:
                print("  sum: <failed>", e)

            # compare with try_first
            try:
                tf = try_first(df, actual)
                print("  try_first:", tf)
            except Exception as e:
                print("  try_first: <ERROR>", e)

    if missing:
        print("\nMISSING (no matching column found):")
        for m in missing:
            print("  -", m)


def _strip_units(col: str) -> str:
    # "Foo[Wh]" -> "Foo"
    return re.sub(r"\s*\[[^\]]+\]\s*$", "", str(col)).strip()

def get_col_value(df, desired_name: str, default=0.0):
    """
    Find a column in df that matches desired_name ignoring trailing [units],
    then return try_first(df, actual_column_name).
    """
    desired_base = _strip_units(desired_name)

    # Build mapping base_name -> actual column name (first occurrence wins)
    base_to_actual = {}
    for c in df.columns:
        base = _strip_units(c)
        base_to_actual.setdefault(base, c)

    actual = base_to_actual.get(desired_base)
    if actual is None:
        return default
    return try_first(df, actual)

def create_new_plot(df):
    convert_units(df)

    # Columns come directly from SIGN
    columns = list(SIGN.keys())

    labels = columns
    values = [signed_value(df, c) for c in columns]

    # NET closes the balance visually
    labels.append("NET")
    values.append(sum(values))

    create_new_barchart(
        title="Zone sensible balance (signed)",
        labels=labels,
        values=values,
    )


def main():
    """Entry point to the script."""
    csv_filename = 'F:\\Repos\\OrgGenSim\\Output\\run\\017_results\\report_variables_ZoneTimestep-Sum.csv'
    frame = read_csv(csv_filename)
    #create_plot(frame)
    create_new_plot(frame)
main()
