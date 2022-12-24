import pandas as pd
import numpy as np
import plotly.graph_objects as go


def unique_counts(df):
    for i in df.columns:
        count = df[i].nunique()
        print(i, count)


# read dataset
orders_df = pd.read_csv("Assessment exercise dataset - orders.csv")
orders_df.head()

# description of df
# --> dimension
print(orders_df.shape, "\n")
# --> col names
print(orders_df.columns.tolist(), "\n")
# --> missing values
missing_val = pd.DataFrame({'missing values': orders_df.isnull().sum() * 100 / len(orders_df)})
print(missing_val, "\n")
# --> num of unique values per column
print(unique_counts(orders_df), "\n")

# create new column with only the date part from order_timestamp and convert to datetime
orders_df["order_date"] = orders_df["order_timestamp"].str.extract("([^\s]+)").fillna(" ")
orders_df["order_date"] = pd.to_datetime(orders_df["order_date"])
# drop unnecessary columns
orders_df = orders_df.drop(["order_id", "order_timestamp", "city", "cuisine", "paid_cash"], axis=1)

# --- RECENCY ---
# find last date of order for each user_id
recency = orders_df.groupby(by="user_id", as_index=False)["order_date"].max()
recency.columns = ["user_id", "last_order"]
# since we have data for January, we need to compute recency based on last dataset date and not current
recent_date = recency["last_order"].max()
# subtract last dataset date from last order date
recency["recency"] = recency["last_order"].apply(lambda x: (recent_date - x).days)
recency.head()

# ---FREQUENCY ---
# count frequency of transactions for each user_id
frequency = orders_df.groupby(by=["user_id"], as_index=False)["order_date"].count()
frequency.columns = ["user_id", "frequency"]
frequency.head()

# --- MONETARY ---
# sum amount column for each user_id
monetary = orders_df.groupby(by="user_id", as_index=False)["amount"].sum()
monetary.columns = ["user_id", "monetary"]
monetary.head()

# merge all three dfs
final_df = recency.merge(frequency, on="user_id")
final_df = final_df.merge(monetary, on="user_id")
final_df.head()
# normalize R,F,M rank values (adjust values to a common scale)
final_df["recency_rank"] = final_df["recency"].rank(ascending=False)
final_df["frequency_rank"] = final_df["frequency"].rank(ascending=True)
final_df["monetary_rank"] = final_df["monetary"].rank(ascending=True)

final_df["recency_rank"] = (final_df["recency_rank"] / final_df["recency_rank"].max()) * 100
final_df["frequency_rank"] = (final_df["frequency_rank"] / final_df["frequency_rank"].max()) * 100
final_df["monetary_rank"] = (final_df["monetary_rank"] / final_df["monetary_rank"].max()) * 100

final_df["RFM"] = 0.15 * final_df["recency_rank"] + 0.28 * final_df["frequency_rank"] + 0.57 * final_df["monetary_rank"]
final_df["RFM"] *= 0.05
final_df = final_df.round(2)

# classify customers according to RMF score
# np arrays better performance than for loop
final_df["segments"] = np.where(final_df["RFM"] > 4.5, "Soulmates",
                                (np.where(final_df["RFM"] > 4, "Lovers",
                                          (np.where(final_df["RFM"] > 3, "Flirting",
                                                    np.where(final_df["RFM"] > 1.6, "Friends",
                                                             "About to dump you"))))))

# plot frequency of segments
colors = ["peachpuff", ] * 5
colors[0] = "crimson"
fig = go.Figure(data=[go.Bar(
    x=final_df.segments.value_counts().index,
    y=final_df.segments.value_counts(),
    marker_color=colors
)])
fig.update_layout(title_text="Segments Frequency")
fig.show()

# df with counts and percentages for each segment
counts = final_df.segments.value_counts()
perc = final_df.segments.value_counts(normalize=True)
count_perc = pd.concat([counts, perc], axis=1, keys=["count", "percentage"])
print(count_perc)
