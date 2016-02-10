STAFF_CSV=$(shell find input/ -name 'GPStaff.csv')
PRACTICE_CSV=$(shell find input/ -name 'GP.csv')

FINAL_JSON=output/general-medical-practitioners.json

.PHONY: all
all: $(FINAL_JSON)

.PHONY: $(FINAL_JSON)
$(FINAL_JSON): $(STAFF_CSV) $(PRACTICE_CSV)
	./process/convert.rb $(STAFF_CSV) $(PRACTICE_CSV) > $(FINAL_JSON)
