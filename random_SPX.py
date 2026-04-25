import random

stations = ["HCM","HN","MT","CT","DN"]
codes=set()

for s in stations:
    count=0
    while count<20:
        num = random.randint(1000000000, 999999999)
        code=f"SPXVN06{num}3"
        if code not in codes:
            weight=round(random.uniform(0.1,3.0),1)
            print(f"{code} | {s} | {weight}")
            codes.add(code)
            count+=1