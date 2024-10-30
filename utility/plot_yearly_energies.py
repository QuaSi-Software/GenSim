import pandas as pd
import matplotlib.pyplot as plt

# Function to read CSV file and extract data
def read_csv(filename):
    df = pd.read_csv(filename)
    print(df.describe())
    print(df.head())
    return df

def JtokWh(x):
    return x /3600000

def JtoMWh(x):
    return JtokWh(x) / 1000

def WtokWh(x):
    return x / 1000

def WtoMWh(x):
    return WtokWh(x) / 1000

def convert_dataframe(dataFrame):
    for column in dataFrame.columns:
        if "[J]" in column:
            dataFrame[column] = dataFrame[column].apply(JtoMWh)
        elif "[W]" in column:
            # check the timestamp and multiply accordingly
            dataFrame[column] = dataFrame[column].apply(WtoMWh)

    dataFrame.rename(columns=lambda c: c.replace('[J]', ''), inplace=True)
    dataFrame.rename(columns=lambda c: c.replace('[W]', ''), inplace=True)


def create_barchart(title_name, mechanical_ventilation_losses, mechanical_ventilation_gains, transmission_trans_losses, transmission_opqaue_losses, transmission_trans_gains, transmission_opqaue_gains,
                    infiltration_losses, infiltration_gains,
                window_ventilation_losses, window_ventilation_gains, solar_gains, internal_gains, heating_gains,
                cooling_losses):
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
            ['Losses', 'Cooling', cooling_losses]])

    # sns.color_palette("Paired")
    colors = [(0.6509803921568628, 0.807843137254902, 0.8901960784313725),
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
                   (0.6941176470588235, 0.34901960784313724, 0.1568627450980392)]
    ax = df.groupby(['Energy balance', 'Name']).sum().unstack().plot(kind='bar', stacked=True, width=0.99, color=colors)
    print(df)
    print(df.groupby(['Energy balance', 'Name']).sum())
    print(df.unstack())
    ax.legend(['Cooling', 'Heating', 'Infiltration', 'Internal',
               'Mechanical Ventilation', 'Solar', 'Transmission Opaque', 'Transmission Transparent', 'Window Ventilation'], bbox_to_anchor=(1.05, 1.0),
              loc='upper left')
    ax.set_title(title_name)
    ax.set_ylabel("MWh")
    plt.tight_layout()
    plt.show()

# Function to create and save the plot
def create_plot(df, output_file):

    convert_dataframe(df)

    # old mapping
    mechanical_ventilation_losses = df["METER MECHANICAL VENTILATION LOSS"][0]
    mechanical_ventilation_gains = 0
    transmission_trans_losses = df["METER SURFACE WINDOW HEAT LOSS ENERGY"][0]
    transmission_opaque_losses = df["METER SURFACE AVERAGE FACE CONDUCTION HEAT LOSS RATE"][0]
    transmission_trans_gains = df["METER SURFACE WINDOW HEAT GAIN ENERGY"][0]
    transmission_opaque_gains = df["METER SURFACE AVERAGE FACE CONDUCTION HEAT GAIN RATE"][0]
    infiltration_losses = 0
    infiltration_gains = 0
    window_ventilation_losses = 0
    window_ventilation_gains = 0
    solar_gains = df["METER ZONE WINDOWS TOTAL TRANSMITTED SOLAR RADIATION ENERGY"][0] - df["METER SURFACE WINDOW HEAT GAIN ENERGY"][0]
    internal_gains = df["METER PEOPLE TOTAL HEATING ENERGY"][0] + df["METER ZONE LIGHTS TOTAL HEATING ENERGY"][0] + df["METER PEOPLE TOTAL HEATING ENERGY"][0]
    heating_gains = df["DistrictHeating:Facility"][0]
    cooling_losses = df["DistrictCooling:Facility"][0]

    create_barchart("Old Mapping", mechanical_ventilation_losses, mechanical_ventilation_gains, transmission_trans_losses, transmission_opaque_losses, transmission_trans_gains, transmission_opaque_gains, infiltration_losses, infiltration_gains,
          window_ventilation_losses, window_ventilation_gains, solar_gains, internal_gains, heating_gains, cooling_losses)

    # new mapping
    mechanical_ventilation_losses = df["METER MECHANICAL VENTILATION LOSS"][0]
    mechanical_ventilation_gains = 0
    transmission_trans_losses = df["METER SURFACE WINDOW HEAT LOSS ENERGY"][0]
    transmission_opaque_losses = df["Surface Inside Face Conduction Heat Loss Rate"][0]
    transmission_trans_gains = 0
    transmission_opaque_gains = df["Surface Inside Face Conduction Heat Gain Rate"][0]
    if "METER ZONE INFILTRATION HEAT LOSS" in df:
        infiltration_losses = df["METER ZONE INFILTRATION HEAT LOSS"][0]
    if "METER ZONE INFILTRATION HEAT GAIN" in df:
        infiltration_gains = df["METER ZONE INFILTRATION HEAT GAIN"][0]
    if "METER ZONE VENTILATION HEAT LOSS" in df:
        window_ventilation_losses = df["METER ZONE VENTILATION HEAT LOSS"][0]
    if "METER ZONE VENTILATION HEAT GAIN" in df:
        window_ventilation_gains = df["METER ZONE VENTILATION HEAT GAIN"][0]

    solar_gains = df["METER SURFACE WINDOW HEAT GAIN ENERGY"][0]
    internal_gains = df["METER PEOPLE TOTAL HEATING ENERGY"][0] + df["METER ZONE LIGHTS TOTAL HEATING ENERGY"][0] + df["METER ZONE ELECTRIC EQUIPMENT TOTAL HEATING ENERGY"][0]
    heating_gains = df["DistrictHeating:Facility"][0]
    cooling_losses = df["DistrictCooling:Facility"][0]

    create_barchart("New Mapping", mechanical_ventilation_losses, mechanical_ventilation_gains, transmission_trans_losses, transmission_opaque_losses, transmission_trans_gains, transmission_opaque_gains, infiltration_losses, infiltration_gains,
          window_ventilation_losses, window_ventilation_gains, solar_gains, internal_gains, heating_gains, cooling_losses)


# Main code
csv_filename = 'C:/Users/tmaile/Documents/GitHub/GenSimEPlus/Output/reports/results_report_variables_ZoneTimestepfiltered-Sum.csv'
output_plot_filename = 'annual_values_bar_chart.png'

df = read_csv(csv_filename)
create_plot(df, output_plot_filename + 'before.png')


