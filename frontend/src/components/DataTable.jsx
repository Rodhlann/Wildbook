import React, { useState, useEffect } from "react";
import DataTable from "react-data-table-component";
import ReactPaginate from "react-paginate";
import { InputGroup, Form, Button, Container, Row, Col } from "react-bootstrap";
import axios from "axios";
import "bootstrap/dist/css/bootstrap.min.css";
import "../css/dataTable.css";

const columns = [
  { name: "ID", selector: (row) => row.id, sortable: true },
  { name: "Name", selector: (row) => row.name, sortable: true },
  { name: "Age", selector: (row) => row.age, sortable: true },
];

const customStyles = {
  rows: {
    style: {
      border: "none !important",
      borderRadius: "5px",
    },
  },
};

const conditionalRowStyles = [
  {
    when: (row) => row.id % 2 === 0,
    style: {
      backgroundColor: "#ffffff", // Light gray color
    },
  },
  {
    when: (row) => row.id % 2 !== 0,
    style: {
      backgroundColor: "#f2f2f2", // White color
    },
  },
];

const MyDataTable = () => {
  const [data, setData] = useState([]);
  const [totalRows, setTotalRows] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(0); // page is zero-based in react-paginate
  const [perPage, setPerPage] = useState(10);
  const [goToPage, setGoToPage] = useState("");

  const fetchData = async (currentPage, perPage) => {
    setLoading(true);
    try {
      const response = {
        data: {
          data: Array.from({ length: perPage }, (_, i) => ({
            id: currentPage * perPage + i + 1,
            name: `John Doe ${currentPage * perPage + i + 1}`,
            age: Math.floor(Math.random() * 100),
          })),
          total: 85,
        },
      };
      setData(response.data.data);
      setTotalRows(response.data.total);
    } catch (error) {
      console.error("Error fetching data:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData(page, perPage);
  }, [page, perPage]);

  const handlePageChange = ({ selected }) => {
    setPage(selected);
  };

  const handleGoToPageChange = (event) => {
    setGoToPage(event.target.value);
  };

  const handleGoToPageSubmit = () => {
    const pageNumber = Number(goToPage) - 1; // react-paginate is zero-based
    if (
      !isNaN(pageNumber) &&
      pageNumber >= 0 &&
      pageNumber < Math.ceil(totalRows / perPage)
    ) {
      setPage(pageNumber);
    }
  };

  const handlePerPageChange = (event) => {
    const newPerPage = Number(event.target.value);
    if (!isNaN(newPerPage) && newPerPage > 0) {
      setPerPage(newPerPage);
    }
  };

  return (
    <Container>
      <DataTable
        title="Server-Side Pagination"
        columns={columns}
        data={data}
        progressPending={loading}
        customStyles={customStyles}
        conditionalRowStyles={conditionalRowStyles}
      />
      <Row className="mt-3 d-flex justify-content-center align-items-center">
        <Col
          xs={12}
          className="d-flex justify-content-center align-items-center flex-nowrap"
        >
          <div className="me-3">
            <span>Total Items: {totalRows}</span>
          </div>
          <InputGroup className="me-3" style={{ width: "150px" }}>
            <InputGroup.Text>Per page</InputGroup.Text>
            <Form.Control
              as="select"
              value={perPage}
              onChange={handlePerPageChange}
            >
              <option value={10}>10</option>
              <option value={20}>20</option>
              <option value={30}>30</option>
              <option value={40}>40</option>
              <option value={50}>50</option>
            </Form.Control>
          </InputGroup>
          <ReactPaginate
            previousLabel={"<"}
            nextLabel={">"}
            breakLabel={"..."}
            breakClassName={"page-item"}
            breakLinkClassName={"page-link"}
            pageCount={Math.ceil(totalRows / perPage)}
            marginPagesDisplayed={2}
            pageRangeDisplayed={5}
            onPageChange={handlePageChange}
            containerClassName={"pagination"}
            pageClassName={"page-item"}
            pageLinkClassName={"page-link"}
            previousClassName={"page-item"}
            previousLinkClassName={"page-link"}
            nextClassName={"page-item"}
            nextLinkClassName={"page-link"}
            activeClassName={"active-page"}
            forcePage={page}
          />
          <InputGroup className="ms-3" style={{ width: "150px" }}>
            <InputGroup.Text>Go to</InputGroup.Text>
            <Form.Control
              type="text"
              value={goToPage}
              onChange={handleGoToPageChange}
            />
            <Button className="go-button" onClick={handleGoToPageSubmit}>
              Go
            </Button>
          </InputGroup>
        </Col>
      </Row>
    </Container>
  );
};

export default MyDataTable;
