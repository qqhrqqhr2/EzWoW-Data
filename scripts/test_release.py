import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location('addon_release', Path(__file__).with_name('release.py'))
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)

class PackageTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.addon = 'EzWoW-Test'
        self.toc = self.root / (self.addon + '.toc')
        self.toc.write_text('## Interface: 16001\n## Version: 1.2.3\n## X-Curse-Project-ID: 42\nmain.lua\n', encoding='utf-8')
        (self.root / 'main.lua').write_text('print("test")\n', encoding='utf-8')
        (self.root / 'RELEASE_NOTES.md').write_text('# v1.2.3\n\n- User-visible fix.\n', encoding='utf-8')
        (self.root / 'release.json').write_text(json.dumps({'addon': self.addon, 'project_id': 42, 'interface': '16001', 'game_version': '1.60.1'}), encoding='utf-8')

    def test_deterministic_zip_and_exclusions(self):
        for name in ('docs', 'scripts', '.git'):
            (self.root / name).mkdir()
            (self.root / name / 'private.txt').write_text('excluded', encoding='utf-8')
        first = release.build(self.root, self.root / 'dist')[0].read_bytes()
        archive, metadata, _, count, _ = release.build(self.root, self.root / 'dist')
        self.assertEqual(first, archive.read_bytes())
        with zipfile.ZipFile(archive) as zipped:
            self.assertEqual(sorted(zipped.namelist()), ['EzWoW-Test/EzWoW-Test.toc', 'EzWoW-Test/main.lua'])
        self.assertEqual(metadata['gameVersionNames'], ['1.60.1'])
        self.assertEqual(count, 2)

    def test_missing_toc_file_rejected(self):
        (self.root / 'main.lua').unlink()
        with self.assertRaisesRegex(ValueError, 'Missing'):
            release.build(self.root, self.root / 'dist')

    def test_missing_xml_include_rejected(self):
        with self.toc.open('a', encoding='utf-8') as out:
            out.write('load.xml\n')
        (self.root / 'load.xml').write_text('<Ui><Script file="missing.lua"/></Ui>', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'Missing'):
            release.build(self.root, self.root / 'dist')

    def test_wrong_project_rejected(self):
        self.toc.write_text(self.toc.read_text().replace('ID: 42', 'ID: 43'), encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'project IDs differ'):
            release.build(self.root, self.root / 'dist')

    def test_stale_release_notes_rejected(self):
        (self.root / 'RELEASE_NOTES.md').write_text('# v1.2.2\n', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'matching the TOC version'):
            release.build(self.root, self.root / 'dist')

    def make_part(self, version='1.2.3'):
        part = self.root / (self.addon + '-Part')
        part.mkdir()
        (part / (self.addon + '-Part.toc')).write_text('## Interface: 16001\n## Version: ' + version + '\n## X-Curse-Project-ID: 42\n## LoadOnDemand: 1\npart.lua\n', encoding='utf-8')
        (part / 'part.lua').write_text('print("part")\n', encoding='utf-8')
        (part / 'LICENSE-DATA-NOTICE.md').write_text('notice\n', encoding='utf-8')
        return part

    def test_extra_addon_folders_packaged_side_by_side(self):
        self.make_part()
        archive, _, _, count, _ = release.build(self.root, self.root / 'dist')
        with zipfile.ZipFile(archive) as zipped:
            self.assertEqual(sorted(zipped.namelist()), ['EzWoW-Test-Part/EzWoW-Test-Part.toc', 'EzWoW-Test-Part/LICENSE-DATA-NOTICE.md',
                                                         'EzWoW-Test-Part/part.lua', 'EzWoW-Test/EzWoW-Test.toc', 'EzWoW-Test/main.lua'])
        self.assertEqual(count, 5)

    def test_extra_addon_version_mismatch_rejected(self):
        self.make_part('1.2.4')
        with self.assertRaisesRegex(ValueError, 'version differs'):
            release.build(self.root, self.root / 'dist')

    def test_extra_addon_missing_file_rejected(self):
        (self.make_part() / 'part.lua').unlink()
        with self.assertRaisesRegex(ValueError, 'Missing'):
            release.build(self.root, self.root / 'dist')

if __name__ == '__main__':
    unittest.main()
