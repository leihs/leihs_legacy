# from <https://github.com/Madek/madek-webapp/blob/47f5206600f05a38964ef594f88f6479d40ea817/config/initializers/madek_semver.rb>

# Semver: get semantic version as a parsed Hash.
#
# Supports one of two cases:
# - deployed on a server, info comes from superproject
# - if not found, its assumed to be a dev instance and shows git info

NAME = 'Leihs'
TAG_LINK = 'https://github.com/leihs/leihs/releases/tag/'
GIT_LINK = 'https://github.com/leihs/leihs/commits/'
TREE_LINK = 'https://ci.zhdk.ch/cider-ci/ui/workspace/trees/'
HISTORY_LINK = 'https://github.com/leihs/leihs/releases?after=4.1.0'

def deploy_info
  @deploy_info ||= begin
    dat = YAML.safe_load(File.read('../config/deploy-info.yml'))
    dat.merge(
      commit_link: GIT_LINK + dat['commit_id'],
      tree_link: TREE_LINK + dat['tree_id'])
  rescue
  end
end

def releases_info
  @releases_info ||= begin YAML.safe_load(
      File.read('../config/releases.yml'))['releases'].map do |r|
        v = semver(r)
        r.merge(
          semver: v,
          name: "#{NAME} #{v}",
          link: "#{TAG_LINK}#{v}",
          description: to_markdown(r['description'])
        )
      end.presence
    rescue Errno::ENOENT => e # ignore file errors
    end
end

def git_hash
  @git_hash ||= \
    if deploy_info then deploy_info['commit_id']
    else
      `git log -n1 --format='%h'`.chomp
    end
end

def semver(release_info)
  version = ['major', 'minor', 'patch']
    .map { |key| release_info.fetch("version_#{key}") }
    .join('.')
  pre = release_info['version_pre'].presence
  pre.nil? ? version : "#{version}-#{pre}"
end

def version_from_archive
  return unless deploy_info.present?
  semver = releases_info.try(:first).try(:[], :semver) || '0.0.0'
  {
    type: 'archive',
    deploy_info: deploy_info,
    version_name: semver
  }
end

def version_from_git
  {
    type: 'git',
    git_hash: git_hash,
    git_url: ("#{GIT_LINK}#{git_hash}" if git_hash.present?),
    version_name: ('git-' + git_hash if git_hash.present?)
  }
end

def to_markdown(source)
  return unless source.is_a?(String)
  opts = { input: 'GFM', hard_wrap: false } # do it like github
  Kramdown::Document.new(source, opts).to_html.html_safe
end

RELEASE_INFO ||= { version_name: '???' }
  .merge(version_from_archive || version_from_git)
  .merge(releases: releases_info, history: HISTORY_LINK)
  .deep_symbolize_keys
  .freeze
