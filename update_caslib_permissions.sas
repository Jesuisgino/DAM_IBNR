%macro update_caslib_permissions(caslib_name=, identity=, identityType=);

    %let m_caslib_name = &caslib_name.;
    %let m_identity = &identity.;
    %let m_identity_type = &identityType.;

    proc cas;
      action accessControl.updSomeAcsCaslib /
        acs={
          {
            caslib="&m_caslib_name",
            identity="&m_identity",
            identityType="&m_identity_type",
            permType="Grant",
            permission="ReadInfo"
          },
          {
            caslib="&m_caslib_name",
            identity="&m_identity",
            identityType="&m_identity_type",
            permType="Grant",
            permission="Select"
          },
          {
            caslib="&m_caslib_name",
            identity="&m_identity",
            identityType="&m_identity_type",
            permType="Grant",
            permission="Insert"
          },
          {
            caslib="&m_caslib_name",
            identity="&m_identity",
            identityType="&m_identity_type",
            permType="Grant",
            permission="Update"
          },
          {
            caslib="&m_caslib_name",
            identity="&m_identity",
            identityType="&m_identity_type",
            permType="Grant",
            permission="Delete"
          },
          {
            caslib="&m_caslib_name",
            identity="&m_identity",
            identityType="&m_identity_type",
            permType="Grant",
            permission="CreateTable"
          },
          {
            caslib="&m_caslib_name",
            identity="&m_identity",
            identityType="&m_identity_type",
            permType="Grant",
            permission="AlterTable"
          },
          {
            caslib="&m_caslib_name",
            identity="&m_identity",
            identityType="&m_identity_type",
            permType="Grant",
            permission="DropTable"
          },
          {
            caslib="&m_caslib_name",
            identity="&m_identity",
            identityType="&m_identity_type",
            permType="Grant",
            permission="Promote"
          },
          {
            caslib="&m_caslib_name",
            identity="&m_identity",
            identityType="&m_identity_type",
            permType="Grant",
            permission="ManageAccess"
          },
          {
            caslib="&m_caslib_name",
            identity="&m_identity",
            identityType="&m_identity_type",
            permType="Grant",
            permission="DeleteSource"
          },
          {
            caslib="&m_caslib_name",
            identity="&m_identity",
            identityType="&m_identity_type",
            permType="Grant",
            permission="LimitedPromote"
          }
        };
    run;
    quit;

%mend update_caslib_permissions;
