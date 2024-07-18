import React, { useEffect, useState } from "react";
import DataTable from "../components/DataTable";
import useFilterEncounters from "../models/encounters/useFilterEncounters";
import FilterPanel from "../components/FilterPanel";
import useEncounterSearchSchemas from "../models/encounters/useEncounterSearchSchemas";
import SideBar from "../components/filterFields/SideBar";

export default function EncounterSearch() {

  const [formFilters, setFormFilters] = useState([]);
  const [filterPanel, setFilterPanel] = useState(true);

  const columns = [
    { name: "Encounter ID", selector: "id" },
    { name: "Sighting ID", selector: "occurrenceId" },
    { name: "Alternative ID", selector: "otherCatalogNumbers" },    
    { name: "Created Date", selector: "date" },
    { name: "Location ID", selector: "locationId" },
    { name: "Species", selector: "taxonomy" },
    { name: "Submitter", selector: "submitters" },
    { name: "Date Submitted", selector: "dateSubmitted" },    
    { name: "Individual ID", selector: "individualId" },    
    { name: "Number Annotations", selector: "numberAnnotations" },    
  ];

  const schemas = useEncounterSearchSchemas();

  const [page, setPage] = useState(0);
  const [perPage, setPerPage] = useState(20);

  const { data: encounterData, loading } = useFilterEncounters({
    queries: formFilters,
    params: {
      sort: "date",
      size: perPage,
      from: page * perPage,
    },
  });

  const encounters = encounterData?.results || [];
  const totalEncounters = encounterData?.resultCount || 0;
  const tabs = [
    "Project Management : /encounters/projectManagement.jsp", 
    "Matching Images/Videos : /encounters/thumbnailSearchResults.jsp",
    "Mapped Results : /encounters/mappedSearchResults.jsp",
    "Results Calendar : /xcalendar/calendar.jsp",
    "Analysis : /encounters/searchResultsAnalysis.jsp",
    "Export : /encounters/exportSearchResults.jsp",
  ];

  return (

    <div className="encounter-search container-fluid"
      style={{
        backgroundImage: "url('/react/images/encounter_search_background.png')",
        backgroundSize: "cover",
        height: "800px",
        width: "100%",
        overflow: "auto",
        padding: "20px",
      }}
    >
      <FilterPanel
        style={{
          display: filterPanel ? "block" : "none",
        }}
        formFilters={formFilters}
        setFormFilters={setFormFilters}
        setFilterPanel={setFilterPanel}
        updateFilters={Function.prototype}
        schemas={schemas}
      />
      <DataTable
        style={{
          display: !filterPanel ? "block" : "none",
        }}
        title="Encounters Search Results"
        columnNames={columns}
        tabs = {tabs}
        tableData={encounters}
        totalItems={totalEncounters}
        page={page}
        perPage={perPage}
        onPageChange={setPage}
        onPerPageChange={setPerPage}
        loading={false}
        onSelectedRowsChange={(selectedRows) => {
          console.log("Selected Rows: ", selectedRows);
        }}
      />
      <SideBar
        formFilters={formFilters}
        setFilterPanel={setFilterPanel}
        setFormFilters={setFormFilters}
      />
    </div>
  );
}
