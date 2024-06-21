import React from "react";
import ThemeColorContext from "../ThemeColorProvider";
import { FormattedMessage } from "react-intl";
import BrutalismButton from "./BrutalismButton";

export default function AlertBanner({ setShowAlert }) {
  const theme = React.useContext(ThemeColorContext);
  return (
    <div
      className="alert alert-warning alert-dismissible fade show d-flex justify-content-between align-items-center"
      role="alert"
      style={{
        padding: 20,
        minHeight: 60,
        backgroundColor: theme.primaryColors.primary100,
        border: "none",
        borderRadius: 0,
        zIndex: 1000,
      }}
    >
      <FormattedMessage id="BANNER_ALERT" />
      <BrutalismButton
        color={theme.primaryColors.primary500}
        borderColor={theme.primaryColors.primary500}
        style={{ padding: 10, margin: 0 }}
        onClick={() => setShowAlert(false)}
      >
        <FormattedMessage id="OK" />
      </BrutalismButton>
    </div>
  );
}
