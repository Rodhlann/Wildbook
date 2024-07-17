import React from "react";
import Description from "../Form/Description";
import { FormattedMessage } from "react-intl";
import FormGroupText from "../Form/FormGroupText";
import { Form, Row, Col } from "react-bootstrap";
import FormDualInputs from "../Form/FormDualInputs";
import { FormGroup, FormLabel, FormControl } from "react-bootstrap";  


export default function TagsFilter({
  data,
  onChange
}) {
  const metalTagLocations = ["left", "right"].map((item) => {
    return {
      value: item,
      label: item
    };
  }) || [];
  console.log("metalTagLocations", metalTagLocations);
  return (
    <div>
      <h3><FormattedMessage id="FILTER_IDENTITY" /></h3>
      <Description>
        <FormattedMessage id="FILTER_IDENTITY_DESC" />
      </Description>
      <h5><FormattedMessage id="FILTER_METAL_TAGS" /></h5>
      {metalTagLocations.map((location) => {
        const field1 = `metalTag.Location`;
        const field2 = "metalTag.Number";
        return (
          <FormGroup>
            <FormLabel><FormattedMessage id={location.label} defaultMessage="" /></FormLabel>

            <FormControl
              type="text"
              placeholder="Type Here"
              onChange={(e) => {
                onChange({
                  filterId: "metalTag",
                  clause: "filter",
                  query: {
                    "bool" : {
                      "must": [
                      {[field1]: location.label},
                      {[field2]: e.target.value,}
                    ]
                    }                    
                  }

                });
              }}
            />
          </FormGroup>
        );
      })}
      <h5><FormattedMessage id="FILTER_ACOUSTIC_TAGS" /></h5>
      {/* <FormDualInputs
        label="acousticTags"
        label1="SERIAL_NUMBER"
        label2="ID"
        onChange={onChange}
      /> */}
      <div className="w-100 d-flex flex-row gap-2" >
      <FormGroup className="w-50">
            <FormLabel><FormattedMessage id={"FILTER_ACOUSTIC_TAG_SERIAL_NUMBER"} defaultMessage="" /></FormLabel>

            <FormControl
              type="text"
              placeholder="Type Here"
              onChange={(e) => {
                onChange({
                  filterId: "acousticTag.serialNumber",
                  clause: "filter",
                  query: {
                    "match" : {
                      "acousticTag.serialNumber": e.target.value
                    }                    
                  }

                });
              }}
            />
          </FormGroup>
          <FormGroup className="w-50">
            <FormLabel><FormattedMessage id={"FILTER_ACOUSTIC_TAG_ID"} defaultMessage="" /></FormLabel>

            <FormControl
              type="text"
              placeholder="Type Here"
              onChange={(e) => {
                onChange({
                  filterId: "acousticTag.idNumber",
                  clause: "filter",
                  query: {
                    "match" : {
                      "acousticTag.idNumber": e.target.value
                    }                    
                  }

                });
              }}
            />
          </FormGroup>
      </div>
      <h5><FormattedMessage id="FILTER_SATELLITE_TAGS" /></h5>
      <FormGroupText
        noDesc={true}
        label="NAME"
        onChange={onChange}
        field={"satelliteTags.name"}
        term={"match"}
        filterId={"satellite Tags Name"}
      />
      <FormGroupText
        noDesc={true}
        label="SERIAL_NUMBER"
        onChange={onChange}
        field={"satelliteTags.serialNumber"}
        term={"match"}
        filterId={"satellite Tags Serial Number"}
      />
      <FormGroupText
        noDesc={true}
        label="ARGOS_PPT_NUMBER"
        onChange={onChange}
        field={"satelliteTags.argosPttNumber"}
        term={"match"}
        filterId={"satellite Tags Argos Ptt Number"}
      />
    </div>
  );
}