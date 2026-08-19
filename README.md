# test-data

Test corpora for slonyk development, redistributed as release assets.

## Releases

- `sst-nes6502-<sha12>` — SingleStepTests nes6502 v1 corpus (per-cycle CPU
  test cases), repackaged from
  [SingleStepTests/65x02](https://github.com/SingleStepTests/65x02) at the
  commit named by the tag.
- `cpu-interrupts-v2-<sha12>` — blargg's cpu_interrupts_v2 test suite (five
  single-test ROMs, the combined multi-test ROM, upstream readme and
  sources), repackaged from
  [christopherpow/nes-test-roms](https://github.com/christopherpow/nes-test-roms)
  at the commit named by the tag.
- `nestest-<version>` — kevtris's nestest CPU test ROM together with the
  Nintendulator golden execution log, fetched from
  <https://www.qmtpro.com/~nes/misc/>. Community-published freeware;
  checksums and provenance ship inside the archive.

## Licensing

The MIT license in this repository covers the repository's own files only.
Release assets contain third-party test data redistributed under its own
upstream terms; each release's notes and the archive itself carry the
applicable license and provenance.
