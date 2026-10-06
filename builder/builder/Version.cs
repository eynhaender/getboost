using System;

namespace builder
{
    public abstract class Version
    {
        public readonly int Major;

        public readonly int Minor;

        public readonly int MajorRevision;

        // NuGet-only 4th version part, for republishing the same Boost release.
        public readonly int PackageRevision;

        public abstract T Switch<T>(
            Func<StableVersion, T> stable, Func<UnstableVersion, T> unstable);

        protected Version(
            int major, int minor, int majorRevision, int packageRevision)
        {
            Major = major;
            Minor = minor;
            MajorRevision = majorRevision;
            PackageRevision = packageRevision;
        }

        public string BaseString
            => Major + "." + Minor + "." + MajorRevision +
                (PackageRevision > 0 ? "." + PackageRevision : "");

        public override string ToString()
            => BaseString;
    }

    public sealed class UnstableVersion : Version
    {
        public readonly string MinorRevision;

        public UnstableVersion(
            int major,
            int minor,
            int majorRevision,
            string minorRevision,
            int packageRevision = 0) :
            base(major, minor, majorRevision, packageRevision)
        {
            MinorRevision = minorRevision;
        }

        public override T Switch<T>(Func<StableVersion, T> stable, Func<UnstableVersion, T> unstable)
            => unstable(this);

        public override string ToString()
            => base.ToString() + "-" + MinorRevision;
    }

    public sealed class StableVersion : Version
    {
        public StableVersion(
            int major, int minor, int majorRevision, int packageRevision = 0) :
            base(major, minor, majorRevision, packageRevision)
        {
        }

        public override T Switch<T>(
            Func<StableVersion, T> stable, Func<UnstableVersion, T> unstable)
            => stable(this);

        public override string ToString()
            => base.ToString();
    }
}
