{
  version:  .version,
  machines: .machines | to_entries | sort | from_entries
}
