UNAMENDED_CSV=$(shell find input/ -name 'egpcur_*.csv')
AMENDMENT_CSVS=$(shell find input/monthly_amendments -name 'egpam_*.csv')
AMENDMENT_PRACTITIONER_CSV=build/combined-amendments-only-gp-practitioners.csv

FINAL_JSON=output/general-medical-practitioners.json

.PHONY: all
all: $(FINAL_JSON)

$(AMENDMENT_PRACTITIONER_CSV): $(AMENDMENT_CSVS)
	cat $(AMENDMENT_CSVS) | grep -e '^"G[0-9]\{7\}' > $(AMENDMENT_PRACTITIONER_CSV)

.PHONY: $(FINAL_JSON)
$(FINAL_JSON): $(UNAMENDED_CSV) $(AMENDMENT_PRACTITIONER_CSV)
	./process/convert.rb $(UNAMENDED_CSV) $(AMENDMENT_PRACTITIONER_CSV) > $(FINAL_JSON)
